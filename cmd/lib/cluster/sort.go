package cluster

import (
	"sort"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ecs"
)

func Sort(clusters []*ecs.Cluster) {
	sort.Sort(ClusterOrder(clusters))
}

type ClusterOrder []*ecs.Cluster

func (list ClusterOrder) Len() int { return len(list) }

func (list ClusterOrder) Swap(i int, j int) { list[i], list[j] = list[j], list[i] }

func (list ClusterOrder) Less(i int, j int) bool {
	return aws.StringValue(list[i].ClusterName) < aws.StringValue(list[j].ClusterName)
}
