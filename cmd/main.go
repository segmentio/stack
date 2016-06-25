package main

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/segmentio/stack/cmd/lib/service"
)

type command map[string](func(string, string, ...string) error)

type commands map[string]command

func main() {
	var cmds = commands{
		"service": {
			"ls": service.CmdList,
		},
	}

	if err := run(cmds, args(os.Args...)); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func args(list ...string) (args []string) {
	if len(list) != 0 {
		args = make([]string, len(list))

		for i, s := range list {
			args[i] = s
		}

		args[0] = filepath.Base(args[0])
	}
	return
}

func run(cmds commands, args []string) (err error) {
	if len(args) < 2 || cmds[args[1]] == nil {
		return help(cmds, args)
	}

	prog, target, cmd := args[0], args[1], cmds[args[1]]

	if len(args) < 3 || cmd[args[2]] == nil {
		return cmdHelp(cmd, prog, target)
	}

	return cmd[args[2]](prog, target, args[3:]...)
}

func help(cmds commands, args []string) (err error) {
	fmt.Printf(`Usage:
    %s [target] [command] ...

Targets:
    %s

`, args[0], strings.Join(list(cmds), "\n    "))
	return
}

func list(cmds commands) (list []string) {
	list = make([]string, 0, len(cmds))
	list = append(list, "help")

	for c := range cmds {
		list = append(list, c)
	}

	sort.Strings(list)
	return
}

func cmdHelp(cmd command, prog string, target string) (err error) {
	fmt.Printf(`Usage:
    %s %s [command] ...

Commands:
    %s

`, prog, target, strings.Join(cmdList(cmd), "\n    "))
	return
}

func cmdList(cmd command) (list []string) {
	list = make([]string, 0, len(cmd))
	list = append(list, "help")

	for c := range cmd {
		list = append(list, c)
	}

	sort.Strings(list)
	return
}
