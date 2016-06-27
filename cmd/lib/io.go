package stack

import (
	"bufio"
	"os"
)

var (
	Stdin  = bufio.NewReader(os.Stdin)
	Stdout = bufio.NewWriter(os.Stdout)
	Stderr = bufio.NewWriter(os.Stderr)
)
