package cluster

import "fmt"

func parseCluster(prog string, target string, cmd string, args []string) (cluster string, err error) {
	if len(args) == 0 {
		err = fmt.Errorf(`Usage:
    %s %s %s [cluster] ...
`, prog, target, cmd)
		return
	}

	cluster = args[0]
	return
}
