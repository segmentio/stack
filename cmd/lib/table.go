package stack

import (
	"fmt"
	"io"
	"strings"
)

type Table struct {
	aligns []int
	widths []int
	cols   []string
	rows   []Row
}

type Row []string

const (
	left = iota
	right
	center
)

func NewTable(columns ...string) *Table {
	return &Table{
		aligns: columnAligns(columns),
		widths: columnWidths(columns),
		cols:   columnNames(columns),
	}
}

func (t *Table) Append(row Row) {
	if len(row) != len(t.cols) {
		panic(fmt.Sprintf("appending row of length %d to table with %d columns", len(row), len(t.cols)))
	}

	for i, w := range t.widths {
		t.widths[i] = intMax(w, len(row[i]))
	}

	t.rows = append(t.rows, row)
}

func (t *Table) WriteTo(w io.Writer) (n int64, err error) {
	var spaces = makeSpaces(t.widths)

	for i, col := range t.cols {
		var c int64

		if c, err = writeCell(w, t.widths[i], col, spaces, left, i == len(t.cols)); err != nil {
			return
		}

		n += c
	}

	if _, err = io.WriteString(w, "\n"); err != nil {
		return
	}

	for _, row := range t.rows {
		for i, item := range row {
			var c int64

			if c, err = writeCell(w, t.widths[i], item, spaces, t.aligns[i], i == len(row)); err != nil {
				return
			}

			n += c
		}

		if _, err = io.WriteString(w, "\n"); err != nil {
			return
		}
	}

	return
}

func makeSpaces(widths []int) (spaces string) {
	return strings.Repeat(" ", widthMax(widths))
}

func columnAligns(cols []string) (aligns []int) {
	aligns = make([]int, len(cols))

	for i, c := range cols {
		a := 0
		if strings.HasPrefix(c, ":") {
			a++
		}
		if strings.HasSuffix(c, ":") {
			a++
		}
		aligns[i] = a
	}

	return
}

func columnNames(cols []string) (names []string) {
	names = make([]string, len(cols))

	for i, c := range cols {
		if strings.HasPrefix(c, ":") {
			c = c[1:]
		}
		if strings.HasSuffix(c, ":") {
			c = c[:len(c)-1]
		}
		names[i] = c
	}

	return
}

func columnWidths(cols []string) (widths []int) {
	widths = make([]int, len(cols))

	for i, c := range cols {
		w := len(c)
		if strings.HasPrefix(c, ":") {
			w--
		}
		if strings.HasSuffix(c, ":") {
			w--
		}
		widths[i] = w
	}

	return
}

func intMax(a int, b int) int {
	if a > b {
		return a
	}
	return b
}

func widthMax(widths []int) (v int) {
	for _, w := range widths {
		if w > v {
			v = w
		}
	}
	return
}

func writeCell(to io.Writer, width int, value string, spaces string, align int, last bool) (n int64, err error) {
	var l int
	var r int

	switch align {
	case left:
		r = width - len(value)

	case right:
		l = width - len(value)

	case center:
		l = (width - len(value)) / 2
		r = width - (len(value) + l)
	}

	if _, err = io.WriteString(to, spaces[:l]); err != nil {
		return
	}

	if _, err = io.WriteString(to, value); err != nil {
		return
	}

	if _, err = io.WriteString(to, spaces[:r]); err != nil {
		return
	}

	if !last {
		if _, err = io.WriteString(to, "  "); err != nil {
			return
		}
	}

	n = int64(width)
	return
}
