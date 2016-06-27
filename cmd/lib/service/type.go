package service

import (
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ecs"
	"github.com/segmentio/stack/cmd/lib/cluster"
	"github.com/segmentio/stack/cmd/lib/task"
)

type Service struct {
	Name         string
	Status       string
	Cluster      string
	Task         string
	DesiredCount int
	PendingCount int
	RunningCount int
	CreatedOn    time.Time
}

func makeService(service *ecs.Service) Service {
	var clusterArn = aws.StringValue(service.ClusterArn)
	var clusterName string

	var taskArn = aws.StringValue(service.TaskDefinition)
	var taskName string

	var err error

	if _, _, clusterName, err = cluster.ParseArn(clusterArn); err != nil {
		clusterName = clusterArn
	}

	if _, _, taskName, err = task.ParseArn(taskArn); err != nil {
		taskName = taskArn
	}

	return Service{
		Name:         aws.StringValue(service.ServiceName),
		Status:       aws.StringValue(service.Status),
		Cluster:      clusterName,
		Task:         taskName,
		DesiredCount: int(aws.Int64Value(service.DesiredCount)),
		PendingCount: int(aws.Int64Value(service.PendingCount)),
		RunningCount: int(aws.Int64Value(service.RunningCount)),
		CreatedOn:    aws.TimeValue(service.CreatedAt).In(time.Local),
	}
}
