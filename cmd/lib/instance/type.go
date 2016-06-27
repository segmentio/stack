package instance

import (
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ecs"
	"github.com/segmentio/stack/cmd/lib/cluster"
)

type Instance struct {
	ID                string
	Status            string
	Cluster           string
	PendingTasksCount int
	RunningTasksCount int
	AgentConnected    bool
}

func makeInstance(clusterArn string, instance *ecs.ContainerInstance) Instance {
	var clusterName string
	var err error

	if _, _, clusterName, err = cluster.ParseArn(clusterArn); err != nil {
		clusterName = clusterArn
	}

	return Instance{
		Cluster:           clusterName,
		ID:                aws.StringValue(instance.Ec2InstanceId),
		Status:            strings.ToLower(aws.StringValue(instance.Status)),
		PendingTasksCount: int(aws.Int64Value(instance.PendingTasksCount)),
		RunningTasksCount: int(aws.Int64Value(instance.RunningTasksCount)),
		AgentConnected:    aws.BoolValue(instance.AgentConnected),
	}
}
