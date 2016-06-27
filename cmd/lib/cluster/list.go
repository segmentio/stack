package cluster

import (
	"sort"
	"strconv"
	"sync"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/client"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ecs"
	"github.com/segmentio/stack/cmd/lib"
)

func CmdList(prog string, target string, cmd string, args ...string) (err error) {
	var clusters []Cluster

	if clusters, err = List(session.New()); err != nil {
		return
	}

	table := stack.NewTable(
		"NAME", ":STATUS:", "INSTANCES:", "SERVICES:", "PENDING TASKS:", "RUNNING TASKS:",
	)

	for _, cluster := range clusters {
		table.Append(stack.Row{
			cluster.Name,
			cluster.Status,
			strconv.Itoa(cluster.RegisteredContainerInstancesCount),
			strconv.Itoa(cluster.ActiveServicesCount),
			strconv.Itoa(cluster.PendingTasksCount),
			strconv.Itoa(cluster.RunningTasksCount),
		})
	}

	return table.Write(stack.Stdout)
}

type ListResult struct {
	Cluster Cluster
	Error   error
}

func List(config client.ConfigProvider) (clusters []Cluster, err error) {
	for r := range ListAsync(config) {
		if r.Error != nil {
			err = stack.AppendError(err, r.Error)
		} else {
			clusters = append(clusters, r.Cluster)
		}
	}
	Sort(clusters)
	return
}

func ListAsync(config client.ConfigProvider) (res <-chan ListResult) {
	cli := ecs.New(config)
	chn := make(chan ListResult, 10)
	go listAsync(cli, chn)
	res = chn
	return
}

func listAsync(client *ecs.ECS, res chan<- ListResult) {
	defer close(res)

	join := &sync.WaitGroup{}
	defer join.Wait()

	arnchn := make(chan ListArnResult, 10)
	go listArnAsync(client, arnchn)

	for arns := range arnchn {
		if arns.Error != nil {
			res <- ListResult{Error: arns.Error}
		} else {
			join.Add(1)
			go describeClustersAsync(client, arns.ClusterArns, join, res)
		}
	}
}

type ListArnResult struct {
	ClusterArns []string
	Error       error
}

func ListArn(config client.ConfigProvider) (arns []string, err error) {
	for r := range ListArnAsync(config) {
		if r.Error != nil {
			err = stack.AppendError(err, r.Error)
		} else {
			arns = append(arns, r.ClusterArns...)
		}
	}
	sort.Strings(arns)
	return
}

func ListArnAsync(config client.ConfigProvider) (res <-chan ListArnResult) {
	cli := ecs.New(config)
	chn := make(chan ListArnResult, 10)
	go listArnAsync(cli, chn)
	res = chn
	return
}

func listArnAsync(client *ecs.ECS, res chan<- ListArnResult) {
	var token *string

	defer close(res)

	for {
		var list *ecs.ListClustersOutput
		var err error

		if list, err = client.ListClusters(&ecs.ListClustersInput{
			NextToken: token,
		}); err != nil {
			res <- ListArnResult{Error: err}
			break
		}

		res <- ListArnResult{ClusterArns: aws.StringValueSlice(list.ClusterArns)}

		if token = list.NextToken; token == nil {
			break
		}
	}
}

func describeClustersAsync(client *ecs.ECS, clusters []string, join *sync.WaitGroup, res chan<- ListResult) {
	defer join.Done()

	if d, err := client.DescribeClusters(&ecs.DescribeClustersInput{
		Clusters: aws.StringSlice(clusters),
	}); err != nil {
		res <- ListResult{Error: err}
	} else {
		for _, c := range d.Clusters {
			res <- ListResult{Cluster: makeCluster(c)}
		}
	}
}
