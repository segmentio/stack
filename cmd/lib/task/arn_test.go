package task

import "testing"

func TestParseArnSuccess(t *testing.T) {
	tests := []struct {
		arn     string
		region  string
		account string
		name    string
	}{
		{
			arn:     "arn:aws:ecs:us-west-2:752180062551:task-definition/default:42",
			region:  "us-west-2",
			account: "752180062551",
			name:    "default:42",
		},
	}

	for _, test := range tests {
		if region, account, name, err := ParseArn(test.arn); err != nil {
			t.Errorf("%#v => %s", test.arn, err)
		} else if region != test.region {
			t.Errorf("%#v => invalid region %#v", test.arn, region)
		} else if account != test.account {
			t.Errorf("%#v => invalid account %#v", test.arn, account)
		} else if name != test.name {
			t.Errorf("%#v => invalid name %#v", test.arn, name)
		}
	}
}

func TestParseArnFailure(t *testing.T) {
	tests := []string{
		"",
		"arn:aws:",
		"arn:aws:ec2:us-west-2:752180062551:task/default",
		"arn:aws:ecs:us-west-2:752180062551:other/default",
		"arn:aws:ecs:us-west-2:752180062551:task/",
	}

	for _, test := range tests {
		if _, _, _, err := ParseArn(test); err == nil {
			t.Errorf("%#v => no error", test)
		}
	}
}
