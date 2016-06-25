package cluster

import (
	"strings"

	"github.com/segmentio/stack/cmd/lib"
)

func ParseArn(arn string) (region string, account string, name string, err error) {
	var product string

	if product, region, account, name, err = stack.ParseArn(arn); err != nil {
		return
	}

	if product != "ecs" {
		err = stack.ArnSyntaxError{arn}
		return
	}

	if !strings.HasPrefix(name, "cluster/") {
		err = stack.ArnSyntaxError{arn}
		return
	}

	if name = name[8:]; len(name) == 0 {
		err = stack.ArnSyntaxError{arn}
		return
	}

	return
}
