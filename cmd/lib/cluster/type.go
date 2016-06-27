package cluster

import (
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ecs"
)

type Cluster struct {
	Name                              string
	Status                            string
	RegisteredContainerInstancesCount int
	ActiveServicesCount               int
	PendingTasksCount                 int
	RunningTasksCount                 int
}

func makeCluster(cluster *ecs.Cluster) Cluster {
	return Cluster{
		Name:   aws.StringValue(cluster.ClusterName),
		Status: strings.ToLower(aws.StringValue(cluster.Status)),
		RegisteredContainerInstancesCount: int(aws.Int64Value(cluster.RegisteredContainerInstancesCount)),
		ActiveServicesCount:               int(aws.Int64Value(cluster.ActiveServicesCount)),
		PendingTasksCount:                 int(aws.Int64Value(cluster.PendingTasksCount)),
		RunningTasksCount:                 int(aws.Int64Value(cluster.RunningTasksCount)),
	}
}
