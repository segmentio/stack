package cluster

import (
	"os"
	"strconv"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ecs"
	"github.com/segmentio/stack/cmd/lib"
)

func CmdList(prog string, target string, args ...string) (err error) {
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
		"NAME", "ARN", ":STATUS:", "INSTANCES:", "SERVICES:", "PENDING:", "RUNNING:",
	)

	for _, c := range describe.Clusters {
		table.Append(stack.Row{
			aws.StringValue(c.ClusterName),
			aws.StringValue(c.ClusterArn),
			aws.StringValue(c.Status),
			strconv.Itoa(int(aws.Int64Value(c.RegisteredContainerInstancesCount))),
			strconv.Itoa(int(aws.Int64Value(c.ActiveServicesCount))),
			strconv.Itoa(int(aws.Int64Value(c.PendingTasksCount))),
			strconv.Itoa(int(aws.Int64Value(c.RunningTasksCount))),
		})
	}

	_, err = table.WriteTo(os.Stdout)
	return
}
