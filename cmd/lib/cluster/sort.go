package cluster

import "sort"

func Sort(clusters []Cluster) {
	sort.Sort(NaturalOrder(clusters))
}

type NaturalOrder []Cluster

func (list NaturalOrder) Len() int { return len(list) }

func (list NaturalOrder) Swap(i int, j int) { list[i], list[j] = list[j], list[i] }

func (list NaturalOrder) Less(i int, j int) bool {
	return list[i].Name < list[j].Name
}
