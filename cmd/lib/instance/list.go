package instance

import (
	"flag"
	"strconv"
	"sync"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/client"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ecs"
	"github.com/segmentio/stack/cmd/lib"
	"github.com/segmentio/stack/cmd/lib/cluster"
)

func CmdList(prog string, target string, cmd string, args ...string) (err error) {
	var flags = flag.NewFlagSet("instance", flag.ContinueOnError)
	var clusters stack.StringList
	var instances []Instance

	flags.Var(&clusters, "cluster", "a comma separated list of the clusters to search for instances in")

	if err = flags.Parse(args); err != nil {
		return
	}

	if instances, err = List(session.New(), clusters...); err != nil {
		return
	}

	table := stack.NewTable(
		"ID", "CLUSTER", ":STATUS:", ":AGENT CONNECTED:", "PENDING TASKS:", "RUNNING TASKS:",
	)

	for _, instance := range instances {
		table.Append(stack.Row{
			instance.ID,
			instance.Cluster,
			instance.Status,
			strconv.FormatBool(instance.AgentConnected),
			strconv.Itoa(instance.PendingTasksCount),
			strconv.Itoa(instance.RunningTasksCount),
		})
	}

	return table.Write(stack.Stdout)
}

type ListResult struct {
	Instance Instance
	Error    error
}

func List(config client.ConfigProvider, clusters ...string) (instances []Instance, err error) {
	for c := range ListAsync(config, clusters...) {
		if c.Error != nil {
			err = stack.AppendError(err, c.Error)
		} else {
			instances = append(instances, c.Instance)
		}
	}
	Sort(instances)
	return
}

func ListAsync(config client.ConfigProvider, clusters ...string) (res <-chan ListResult) {
	var cli = ecs.New(config)
	var chn = make(chan ListResult, 10)
	var arg <-chan cluster.ListArnResult

	if len(clusters) == 0 {
		arg = cluster.ListArnAsync(config)
	} else {
		c := make(chan cluster.ListArnResult, len(clusters))
		c <- cluster.ListArnResult{ClusterArns: clusters}
		arg = c
		close(c)
	}

	go listAsync(cli, arg, chn)
	res = chn
	return
}

func listAsync(client *ecs.ECS, arg <-chan cluster.ListArnResult, res chan<- ListResult) {
	defer close(res)

	join := &sync.WaitGroup{}
	defer join.Wait()

	for c := range arg {
		if c.Error != nil {
			res <- ListResult{Error: c.Error}
		} else {
			join.Add(len(c.ClusterArns))
			for _, arn := range c.ClusterArns {
				go listClusterAsync(client, join, arn, res)
			}
		}
	}
}

func listClusterAsync(client *ecs.ECS, join *sync.WaitGroup, cluster string, res chan<- ListResult) {
	var token *string

	defer join.Done()

	for {
		var list *ecs.ListContainerInstancesOutput
		var err error

		if list, err = client.ListContainerInstances(&ecs.ListContainerInstancesInput{
			Cluster:   aws.String(cluster),
			NextToken: token,
		}); err != nil {
			res <- ListResult{Error: err}
			break
		}

		if len(list.ContainerInstanceArns) != 0 {
			join.Add(1)
			go describeContainerInstancesAsync(client, join, cluster, list.ContainerInstanceArns, res)
		}

		if token = list.NextToken; token == nil {
			break
		}
	}
}

func describeContainerInstancesAsync(client *ecs.ECS, join *sync.WaitGroup, cluster string, instances []*string, res chan<- ListResult) {
	defer join.Done()

	if d, err := client.DescribeContainerInstances(&ecs.DescribeContainerInstancesInput{
		Cluster:            aws.String(cluster),
		ContainerInstances: instances,
	}); err != nil {
		res <- ListResult{Error: err}
	} else {
		for _, instance := range d.ContainerInstances {
			res <- ListResult{Instance: makeInstance(cluster, instance)}
		}
	}
}
