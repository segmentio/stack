package service

import (
	"sort"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ecs"
)

func Sort(services []*ecs.Service) {
	sort.Sort(ServiceOrder(services))
}

type ServiceOrder []*ecs.Service

func (list ServiceOrder) Len() int { return len(list) }

func (list ServiceOrder) Swap(i int, j int) { list[i], list[j] = list[j], list[i] }

func (list ServiceOrder) Less(i int, j int) bool {
	c1 := aws.StringValue(list[i].ClusterArn)
	c2 := aws.StringValue(list[j].ClusterArn)

	if c1 != c2 {
		return c1 < c2
	}

	s1 := aws.StringValue(list[i].ServiceName)
	s2 := aws.StringValue(list[j].ServiceName)

	if s1 != s2 {
		return s1 < s2
	}

	t1 := aws.StringValue(list[i].TaskDefinition)
	t2 := aws.StringValue(list[j].TaskDefinition)

	if t1 != t2 {
		return t1 < t2
	}

	d1 := aws.TimeValue(list[i].CreatedAt)
	d2 := aws.TimeValue(list[j].CreatedAt)
	return d1.Before(d2)
}
