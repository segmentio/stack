package service

import "sort"

func Sort(services []Service) {
	sort.Sort(NaturalOrder(services))
}

type NaturalOrder []Service

func (list NaturalOrder) Len() int { return len(list) }

func (list NaturalOrder) Swap(i int, j int) { list[i], list[j] = list[j], list[i] }

func (list NaturalOrder) Less(i int, j int) bool {
	c1 := list[i].Cluster
	c2 := list[j].Cluster

	if c1 != c2 {
		return c1 < c2
	}

	s1 := list[i].Name
	s2 := list[j].Name

	if s1 != s2 {
		return s1 < s2
	}

	t1 := list[i].Task
	t2 := list[j].Task

	if t1 != t2 {
		return t1 < t2
	}

	d1 := list[i].CreatedOn
	d2 := list[j].CreatedOn
	return d1.Before(d2)
}
