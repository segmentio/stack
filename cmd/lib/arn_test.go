package stack

import "testing"

func TestParseArnSuccess(t *testing.T) {
	tests := []struct {
		arn      string
		product  string
		region   string
		account  string
		resource string
	}{
		{
			arn:      "arn:aws:ecs:us-west-2:752180062551:cluster/default",
			product:  "ecs",
			region:   "us-west-2",
			account:  "752180062551",
			resource: "cluster/default",
		},
	}

	for _, test := range tests {
		if product, region, account, resource, err := ParseArn(test.arn); err != nil {
			t.Errorf("%#v => %s", test.arn, err)
		} else if product != test.product {
			t.Errorf("%#v => invalid product %#v", test.arn, product)
		} else if region != test.region {
			t.Errorf("%#v => invalid region %#v", test.arn, region)
		} else if account != test.account {
			t.Errorf("%#v => invalid account %#v", test.arn, account)
		} else if resource != test.resource {
			t.Errorf("%#v => invalid resource %#v", test.arn, resource)
		}
	}
}

func TestParseArnFailure(t *testing.T) {
	tests := []string{
		"",
		"arn:aws:",
		"arn:aws:ecs::752180062551:cluster/default",
	}

	for _, test := range tests {
		if _, _, _, _, err := ParseArn(test); err == nil {
			t.Errorf("%#v => no error", test)
		}
	}
}
