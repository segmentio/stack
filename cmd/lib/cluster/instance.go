package cluster

import (
	"os"
	"strconv"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ecs"
	"github.com/segmentio/stack/cmd/lib"
)

func CmdInstances(prog string, target string, cmd string, args ...string) (err error) {
	var client = ecs.New(session.New())
	var cluster string
	var list *ecs.ListContainerInstancesOutput
	var describe *ecs.DescribeContainerInstancesOutput

	if cluster, err = parseCluster(prog, target, cmd, args); err != nil {
		return
	}

	if list, err = client.ListContainerInstances(&ecs.ListContainerInstancesInput{
		Cluster: aws.String(cluster),
	}); err != nil {
		return
	}

	if describe, err = client.DescribeContainerInstances(&ecs.DescribeContainerInstancesInput{
		Cluster:            aws.String(cluster),
		ContainerInstances: list.ContainerInstanceArns,
	}); err != nil {
		return
	}

	table := stack.NewTable(
		"ID", ":STATUS:", ":AGENT CONNECTED:", "PENDING TASKS:", "RUNNING TASKS:",
	)

	for _, instance := range describe.ContainerInstances {
		table.Append(stack.Row{
			aws.StringValue(instance.Ec2InstanceId),
			aws.StringValue(instance.Status),
			strconv.FormatBool(aws.BoolValue(instance.AgentConnected)),
			strconv.Itoa(int(aws.Int64Value(instance.PendingTasksCount))),
			strconv.Itoa(int(aws.Int64Value(instance.RunningTasksCount))),
		})
	}

	_, err = table.WriteTo(os.Stdout)
	return
}
