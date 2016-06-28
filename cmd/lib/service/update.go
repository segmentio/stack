package service

import (
	"bytes"
	"flag"
	"fmt"
	"io/ioutil"
	"os"

	"github.com/hashicorp/hcl/hcl/printer"
	"github.com/hashicorp/hcl/hcl/token"
	"github.com/segmentio/stack/cmd/lib"
)

func CmdUpdate(prog string, target string, cmd string, args ...string) (err error) {
	var flags = flag.NewFlagSet("service", flag.ContinueOnError)
	var image string
	var name string
	var version string
	var path stack.Path
	var plan bool
	var services []findResult

	flags.StringVar(&image, "image", "", "the docker image of services that need to be updated")
	flags.StringVar(&name, "name", "", "the name of the service that need to be updated")
	flags.StringVar(&version, "version", "", "the new version of the services")
	flags.BoolVar(&plan, "plan", false, "when this flag is set the update isn't executed")
	flags.Var(&path, "path", "the paths to the directories contanining the terraform service definitions")

	if err = flags.Parse(args); err != nil {
		return
	}

	if len(path) == 0 {
		path = stack.Path{"."}
	}

	if len(image) == 0 && len(name) == 0 {
		return fmt.Errorf(`Usage:
    %s %s %s [-image | -name] ...

Error:
    one of -image or -name must be provided
`, prog, target, cmd)
	}

	if len(image) != 0 && len(name) != 0 {
		return fmt.Errorf(`Usage:
    %s %s %s [-image | -name] ...

Error:
    only one of -image or -name must be provided
`, prog, target, cmd)
	}

	if len(name) != 0 && len(version) == 0 {
		return fmt.Errorf(`Usage:
    %s %s %s -name [service] -version [version] ...

Error:
    -version must be specified when services are identified by name
`, prog, target, cmd)
	}

	if len(name) != 0 {
		if services = find(name, path...); len(services) == 0 {
			return fmt.Errorf("%s no services found for the given service name", name)
		}
	} else {
		var img Image

		if img, err = ParseImage(image); err != nil {
			return
		}

		if version = img.Version; len(version) == 0 {
			return fmt.Errorf("%s: missing version in the given docker image", image)
		}

		if services = findImage(img.Base(), path...); len(services) == 0 {
			return fmt.Errorf("%s: no services found for the given docker image", img.Base())
		}
	}

	n := 0
	b := &bytes.Buffer{}
	b.Grow(16384)

	for _, service := range services {
		if version == service.image.Version {
			continue
		}

		n++
		fmt.Printf("\n\033[33m~ %s\033[0m\n    version: \"%s\" => \"%s\"\n", service.name, service.image.Version, version)

		if plan {
			continue
		}

		(*(service.version)).Token = token.Token{
			Type: token.STRING,
			Text: "\"" + version + "\"",
		}

		printer.Fprint(b, service.file.Node)
		b.WriteString("\n")

		if err = ioutil.WriteFile(service.path, b.Bytes(), os.FileMode(0644)); err != nil {
			fmt.Println(err)
			return
		}

		b.Reset()
	}

	if n != 0 {
		fmt.Println()
	}

	return
}
