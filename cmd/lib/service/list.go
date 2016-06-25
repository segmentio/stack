package service

import (
	"flag"
	"os"
	"strconv"
	"strings"
	"sync/atomic"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ecs"
	"github.com/segmentio/stack/cmd/lib"
	"github.com/segmentio/stack/cmd/lib/cluster"
	"github.com/segmentio/stack/cmd/lib/task"
)

func CmdList(prog string, target string, cmd string, args ...string) (err error) {
	var flags = flag.NewFlagSet("service", flag.ContinueOnError)
	var client = ecs.New(session.New())
	var list *ecs.ListClustersOutput
	var filter string

	flags.StringVar(&filter, "cluster", "", "the cluster to search for services in")

	if err = flags.Parse(args); err != nil {
		return
	}

	if len(filter) != 0 {
		list = &ecs.ListClustersOutput{ClusterArns: []*string{aws.String(filter)}}
	} else {
		if list, err = client.ListClusters(nil); err != nil {
			return
		}
	}

	counter := int32(len(list.ClusterArns))
	services := make([]*ecs.Service, 0, 100)
	servchan := make(chan *ecs.Service, 100)

	if len(list.ClusterArns) != 0 {
		for _, cluster := range list.ClusterArns {
			go func(client *ecs.ECS, cluster string, outchan chan<- *ecs.Service, counter *int32) {
				defer func() {
					if atomic.AddInt32(counter, -1) == 0 {
						close(outchan)
					}
				}()
				if services, err := ListCluster(client, cluster); err == nil {
					for _, s := range services {
						outchan <- s
					}
				}
			}(client, aws.StringValue(cluster), servchan, &counter)
		}

		for s := range servchan {
			services = append(services, s)
		}
	}

	table := stack.NewTable(
		"NAME", "STATUS", "CLUSTER", "TASK", "DESIRED COUNT:", "PENDING COUNT:", "RUNNING COUNT:", "CREATED ON",
	)

	Sort(services)

	for _, service := range services {
		_, _, cluster, _ := cluster.ParseArn(aws.StringValue(service.ClusterArn))
		_, _, task, _ := task.ParseArn(aws.StringValue(service.TaskDefinition))
		table.Append(stack.Row{
			aws.StringValue(service.ServiceName),
			strings.ToLower(aws.StringValue(service.Status)),
			cluster,
			task,
			strconv.Itoa(int(aws.Int64Value(service.DesiredCount))),
			strconv.Itoa(int(aws.Int64Value(service.PendingCount))),
			strconv.Itoa(int(aws.Int64Value(service.RunningCount))),
			aws.TimeValue(service.CreatedAt).In(time.Local).Format(time.RFC1123),
		})
	}

	_, err = table.WriteTo(os.Stdout)
	return
}

func ListCluster(client *ecs.ECS, cluster string) (services []*ecs.Service, err error) {
	var list *ecs.ListServicesOutput
	var token *string
	var counter int32 = 1
	var reschan = make(chan *ecs.Service, 100)

	for {
		if list, err = client.ListServices(&ecs.ListServicesInput{
			Cluster:   aws.String(cluster),
			NextToken: token,
		}); err != nil {
			return
		}

		if len(list.ServiceArns) == 0 {
			break
		}

		atomic.AddInt32(&counter, 1)

		go func(services []*string, counter *int32) {
			defer func() {
				if atomic.AddInt32(counter, -1) == 0 {
					close(reschan)
				}
			}()

			if describe, err := client.DescribeServices(&ecs.DescribeServicesInput{
				Cluster:  aws.String(cluster),
				Services: services,
			}); err == nil {
				for _, s := range describe.Services {
					reschan <- s
				}
			}
		}(list.ServiceArns, &counter)

		if token = list.NextToken; token == nil {
			break
		}
	}

	if atomic.AddInt32(&counter, -1) == 0 {
		close(reschan)
	}

	for s := range reschan {
		services = append(services, s)
	}

	return
}
