package task

import (
	"strings"

	"github.com/segmentio/stack/cmd/lib"
)

func ParseArn(arn string) (region string, account string, task string, err error) {
	var product string

	if product, region, account, task, err = stack.ParseArn(arn); err != nil {
		return
	}

	if product != "ecs" {
		err = stack.ArnSyntaxError{arn}
		return
	}

	if !strings.HasPrefix(task, "task-definition/") {
		err = stack.ArnSyntaxError{arn}
		return
	}

	if task = task[16:]; len(task) == 0 {
		err = stack.ArnSyntaxError{arn}
		return
	}

	return
}
