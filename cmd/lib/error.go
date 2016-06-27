package stack

import (
	"bytes"
	"fmt"
)

type ErrorList []error

func (err ErrorList) Error() string {
	b := &bytes.Buffer{}
	b.Grow(100 * len(err))

	for _, e := range err {
		fmt.Fprintf(b, "- %s\n", e)
	}

	return b.String()
}

func AppendError(list error, err error) error {
	if list == nil {
		return ErrorList{err}
	}
	switch e := list.(type) {
	case ErrorList:
		return append(e, err)
	default:
		return ErrorList{e, err}
	}
}
