package stack

import (
	"bufio"
	"bytes"
	"io"
	"os"

	"golang.org/x/crypto/ssh/terminal"
)

var (
	Stdout = NewTerm(os.Stdout)
	Stderr = NewTerm(os.Stderr)
)

type Term struct {
	buf *bufio.Writer
	tty bool
}

func NewTerm(w io.Writer) *Term {
	return &Term{
		buf: bufio.NewWriter(w),
		tty: istty(w),
	}
}

func (t *Term) WriteString(s string) (n int, err error) {
	return t.Write([]byte(s))
}

func (t *Term) Write(b []byte) (n int, err error) {
	for len(b) != 0 {
		var a []byte
		var c int
		var i int

		if i = bytes.IndexByte(b, '\n'); i >= 0 {
			i++
			a, b = b[:i], b[i:]
		} else {
			a, b = b, nil
		}

		if c, err = t.write(a); err != nil {
			return
		}

		n += c

		if i >= 0 {
			if err = t.Flush(); err != nil {
				return
			}
		}
	}

	return
}

func (t *Term) Flush() (err error) {
	return t.buf.Flush()
}

func (t *Term) write(b []byte) (n int, err error) {
	if t.tty {
		return t.buf.Write(b)
	}

	tcap := [...]byte{'\033', '['}

	for len(b) != 0 {
		var a []byte
		var i int
		var j int
		var c int

		if i = bytes.Index(b, tcap[:]); i < 0 {
			a, b = b, nil
		} else if i > 0 {
			a, b = b[:i], b[i:]
		} else if j = bytes.IndexByte(b[i:], 'm'); j < 0 {
			a, b = b, nil
		} else {
			b = b[j+1:]
			continue
		}

		if c, err = t.buf.Write(a); err != nil {
			return
		}

		n += c
	}

	return
}

func istty(w io.Writer) bool {
	if f, ok := w.(*os.File); ok {
		return terminal.IsTerminal(int(f.Fd()))
	}
	return false
}
