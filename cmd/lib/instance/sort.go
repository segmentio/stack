package instance

import "sort"

func Sort(instances []Instance) {
	sort.Sort(NaturalOrder(instances))
}

type NaturalOrder []Instance

func (list NaturalOrder) Len() int { return len(list) }

func (list NaturalOrder) Swap(i int, j int) { list[i], list[j] = list[j], list[i] }

func (list NaturalOrder) Less(i int, j int) bool {
	c1 := list[i].Cluster
	c2 := list[j].Cluster

	if c1 != c2 {
		return c1 < c2
	}

	return list[i].ID < list[j].ID
}
