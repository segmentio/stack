package service

import "strings"

type Image struct {
	Org     string
	Name    string
	Version string
}

func ParseImage(s string) (img Image, err error) {
	var str = s
	var org string
	var name string
	var version string
	var ok bool

	if org, str, ok = parseImageOrg(str); !ok {
		err = ImageError{s}
		return
	}

	if name, version, ok = parseImageName(str); !ok {
		err = ImageError{s}
		return
	}

	if len(name) == 0 {
		err = ImageError{s}
		return
	}

	img = Image{
		Org:     org,
		Name:    name,
		Version: version,
	}
	return
}

func parseImageOrg(str string) (org string, next string, ok bool) {
	if index := strings.IndexRune(str, '/'); index == 0 {
		return
	} else if index > 0 {
		org, next = str[:index], str[index+1:]
	} else {
		next = str
	}
	ok = true
	return
}

func parseImageName(str string) (name string, next string, ok bool) {
	if index := strings.IndexRune(str, ':'); index == 0 {
		return
	} else if index > 0 {
		name, next = str[:index], str[index+1:]
	} else {
		name = str
	}
	ok = true
	return
}

func (img Image) Canonical() Image {
	if len(img.Version) == 0 {
		img.Version = "latest"
	}
	return img
}

func (img Image) String() string {
	img = img.Canonical()

	if len(img.Org) == 0 {
		return img.Name + ":" + img.Version
	}

	return img.Org + "/" + img.Name + ":" + img.Version
}

type ImageError struct {
	Image string
}

func (err ImageError) Error() string {
	return "invalid image: " + err.Image
}
