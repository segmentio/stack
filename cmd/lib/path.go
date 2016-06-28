package stack

import "strings"

type Path []string

func (p *Path) String() string {
	return strings.Join([]string(*p), ":")
}

func (p *Path) Set(v string) (err error) {
	*p = Path(strings.Split(v, ":"))
	return
}

func (p *Path) Get() interface{} {
	return []string(*p)
}
