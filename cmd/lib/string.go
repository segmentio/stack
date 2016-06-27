package stack

import "strings"

type StringList []string

func (s *StringList) String() string {
	return strings.Join([]string(*s), ",")
}

func (s *StringList) Set(v string) (err error) {
	*s = append(*s, strings.Split(v, ",")...)
	return
}

func (s *StringList) Get() interface{} {
	return []string(*s)
}
