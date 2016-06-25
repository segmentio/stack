package stack

import "strings"

type ArnSyntaxError struct {
	Arn string
}

func (err ArnSyntaxError) Error() string {
	return "invalid arn: " + err.Arn
}

func ParseArn(arn string) (product string, region string, account string, resource string, err error) {
	if !strings.HasPrefix(arn, "arn:aws:") {
		err = ArnSyntaxError{arn}
		return
	}

	parts := strings.SplitN(arn[8:], ":", 4)

	if len(parts) != 4 {
		err = ArnSyntaxError{arn}
		return
	}

	for _, part := range parts {
		if len(part) == 0 {
			err = ArnSyntaxError{arn}
			return
		}
	}

	product, region, account, resource = parts[0], parts[1], parts[2], parts[3]
	return
}
