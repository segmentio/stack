package service

import (
	"io/ioutil"
	"os"
	"path"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/hashicorp/hcl"
	"github.com/hashicorp/hcl/hcl/ast"
	"github.com/hashicorp/hcl/hcl/token"
)

type findResult struct {
	module  string
	name    string
	path    string
	image   Image
	file    *ast.File
	version *ast.LiteralType
}

func find(name string, paths ...string) []findResult {
	return findFilter(paths, func(r findResult) bool { return r.name == name })
}

func findImage(image string, paths ...string) []findResult {
	return findFilter(paths, func(r findResult) bool { return r.image.Base() == image })
}

func findFilter(paths []string, check func(findResult) bool) (res []findResult) {
	for _, path := range paths {
		res = findInpath(path, check, res)
	}
	return
}

func findInpath(path string, check func(findResult) bool, res []findResult) []findResult {
	var dir *os.File
	var err error
	var files []os.FileInfo

	if dir, err = os.Open(path); err != nil {
		return res
	}

	defer dir.Close()

	if files, err = dir.Readdir(-1); err != nil {
		return res
	}

	for _, f := range files {
		if name := f.Name(); strings.HasSuffix(name, ".tf") && f.Mode().IsRegular() {
			res = findInFile(filepath.Join(path, name), check, res)
		}
	}

	return res
}

func findInFile(file string, check func(findResult) bool, res []findResult) []findResult {
	var f *ast.File
	var b []byte
	var e error

	if b, e = ioutil.ReadFile(file); e != nil {
		return res
	}

	if f, e = hcl.ParseBytes(b); e != nil {
		return res
	}

	switch x := f.Node.(type) {
	case *ast.ObjectList:
		res = findInObjectList(file, x, check, res)
		for i := range res {
			res[i].file = f
		}
	}

	return res
}

func findInObjectList(path string, list *ast.ObjectList, check func(findResult) bool, res []findResult) []findResult {
	for _, item := range list.Items {
		var err error

		if kind := kindOf(item); kind != "module" {
			continue
		}

		if source, _ := sourceOf(item); source != "github.com/segmentio/stack/service" && source != "github.com/segmentio/stack/web-service" {
			continue
		}

		name, _ := nameOf(item)
		image, _ := imageOf(item)
		version, node := versionOf(item)

		result := findResult{
			name:    name,
			path:    path,
			version: node,
		}

		if result.image, err = ParseImage(image + ":" + version); err != nil {
			continue
		}

		if len(result.name) == 0 {
			result.name = defaultServiceName(result.image)
		}

		result.image = result.image.Canonical()

		if check(result) {
			if obj, ok := item.Val.(*ast.ObjectType); ok && result.version == nil {
				result.version = defaultVersionNode(obj)
			}
			res = append(res, result)
		}
	}
	return res
}

func kindOf(item *ast.ObjectItem) (kind string) {
	if len(item.Keys) > 0 {
		kind = item.Keys[0].Token.Text
	}
	return
}

func sourceOf(item *ast.ObjectItem) (source string, node *ast.LiteralType) {
	source, node = valueOf(item, "source")
	source = path.Clean(source)
	return
}

func nameOf(item *ast.ObjectItem) (source string, node *ast.LiteralType) {
	return valueOf(item, "name")
}

func imageOf(item *ast.ObjectItem) (image string, node *ast.LiteralType) {
	return valueOf(item, "image")
}

func versionOf(item *ast.ObjectItem) (version string, node *ast.LiteralType) {
	return valueOf(item, "version")
}

func valueOf(item *ast.ObjectItem, name string) (value string, node *ast.LiteralType) {
	switch v := item.Val.(type) {
	case *ast.ObjectType:
		for _, i := range v.List.Items {
			for _, k := range i.Keys {
				if k.Token.Text == name {
					switch v := i.Val.(type) {
					case *ast.LiteralType:
						return unquote(v.Token.Text), v
					}
				}
			}
		}
	}
	return
}

func unquote(s string) string {
	s, _ = strconv.Unquote(s)
	return s
}

func quote(s string) string {
	return strconv.Quote(s)
}

func defaultServiceName(image Image) string {
	return strings.Replace(image.Base(), "/", "-", -1)
}

func defaultVersionNode(obj *ast.ObjectType) (node *ast.LiteralType) {
	node = &ast.LiteralType{}
	obj.List.Add(&ast.ObjectItem{
		Keys: []*ast.ObjectKey{
			&ast.ObjectKey{
				Token: token.Token{
					Type: token.STRING,
					Text: "version",
				},
			},
			&ast.ObjectKey{
				Token: token.Token{
					Type: token.ASSIGN,
					Text: "=",
				},
			},
		},
		Val: node,
	})
	return
}
