package cluster

import (
	"os"
	"strconv"
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ecs"
	"github.com/segmentio/stack/cmd/lib"
)

func CmdList(prog string, target string, cmd string, args ...string) (err error) {
	var client = ecs.New(session.New())
	var list *ecs.ListClustersOutput
	var describe *ecs.DescribeClustersOutput

	if list, err = client.ListClusters(nil); err != nil {
		return
	}

	if describe, err = client.DescribeClusters(&ecs.DescribeClustersInput{
		Clusters: list.ClusterArns,
	}); err != nil {
		return
	}

	table := stack.NewTable(
		"NAME", ":STATUS:", "INSTANCES:", "SERVICES:", "PENDING TASKS:", "RUNNING TASKS:",
	)

	for _, cluster := range describe.Clusters {
		table.Append(stack.Row{
			aws.StringValue(cluster.ClusterName),
			strings.ToLower(aws.StringValue(cluster.Status)),
			strconv.Itoa(int(aws.Int64Value(cluster.RegisteredContainerInstancesCount))),
			strconv.Itoa(int(aws.Int64Value(cluster.ActiveServicesCount))),
			strconv.Itoa(int(aws.Int64Value(cluster.PendingTasksCount))),
			strconv.Itoa(int(aws.Int64Value(cluster.RunningTasksCount))),
		})
	}

	_, err = table.WriteTo(os.Stdout)
	return
}
