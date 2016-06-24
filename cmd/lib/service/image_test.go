package service

import (
	"fmt"
	"testing"
)

func TestImageCanonical(t *testing.T) {
	tests := []struct {
		in  Image
		out Image
	}{
		{
			in:  Image{Name: "stack"},
			out: Image{Name: "stack", Version: "latest"},
		},
		{
			in:  Image{Name: "stack", Version: "1.2.3"},
			out: Image{Name: "stack", Version: "1.2.3"},
		},
	}

	for _, test := range tests {
		if img := test.in.Canonical(); img != test.out {
			t.Errorf("%#v => %#v", test.in, img)
		}
	}
}

func TestImageString(t *testing.T) {
	tests := []struct {
		img Image
		str string
	}{
		{
			img: Image{Name: "stack"},
			str: "stack:latest",
		},
		{
			img: Image{Org: "segment", Name: "stack", Version: "1.2.3"},
			str: "segment/stack:1.2.3",
		},
	}

	for _, test := range tests {
		if str := test.img.String(); str != test.str {
			t.Errorf("%#v => %#v", test.img, str)
		}
	}
}

func TestParseImageSuccess(t *testing.T) {
	tests := []struct {
		img Image
		str string
	}{
		{
			img: Image{Name: "stack"},
			str: "stack",
		},
		{
			img: Image{Name: "stack", Version: "1.2.3"},
			str: "stack:1.2.3",
		},
		{
			img: Image{Org: "segment", Name: "stack"},
			str: "segment/stack",
		},
		{
			img: Image{Org: "segment", Name: "stack", Version: "1.2.3"},
			str: "segment/stack:1.2.3",
		},
	}

	for _, test := range tests {
		if img, err := ParseImage(test.str); err != nil {
			t.Errorf("%#v => error", test.str)
		} else if img != test.img {
			t.Errorf("%#v => %#v", test.str, img)
		}
	}
}

func TestParseImageFailure(t *testing.T) {
	tests := []string{
		"",
		"/stack",
		"segment/:1.2.3",
	}

	for _, test := range tests {
		if _, err := ParseImage(test); err == nil {
			t.Errorf("%#v => no error", test)
		} else if s := err.Error(); s != fmt.Sprintf("invalid image: %s", test) {
			t.Error("bad error message:", s)
		}
	}
}
