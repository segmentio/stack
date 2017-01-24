variable "name" {
  description = "The name of the stack to use in security groups"
}

variable "environment" {
  description = "The name of the environment for this stack"
}

variable "ecs_role_services" {
  description = ""
  default     = "\"ec2.amazonaws.com\""
}

variable "aws_iam_role_policy_allow" {
  description = ""
  default     = "\"autoscaling:*\",\"cloudwatch:*\""
}

data "template_file" "aws_iam_role" {
  template = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          $${ecs_role_services}
        ]
      },
      "Effect": "Allow"
    }
  ]
}
EOF

  vars {
    ecs_role_services = "${var.ecs_role_services}"
  }
}

resource "aws_iam_role" "default_ecs_role" {
  name               = "ecsrole-${var.name}-${var.environment}"
  assume_role_policy = "${data.template_file.aws_iam_role.rendered}"
}

resource "aws_iam_role_policy" "default_ecs_service_role_policy" {
  name = "ecs-servicerole-policy-${var.name}-${var.environment}"
  role = "${aws_iam_role.default_ecs_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:Describe*",
        "s3:*",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "cloudwatch:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

data "template_file" "aws_iam_role_policy" {
  template = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        $${allow_actions}
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "cloudwatch:*"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF

  vars {
    allow_actions = "${var.aws_iam_role_policy_allow}"
  }
}

resource "aws_iam_role_policy" "default_ecs_instance_role_policy" {
  name = "ecs-instancerole-policy-${var.name}-${var.environment}"
  role = "${aws_iam_role.default_ecs_role.id}"

  policy = "${data.template_file.aws_iam_role_policy.rendered}"
}

resource "aws_iam_instance_profile" "default_ecs" {
  name  = "ecs-instance-profile-${var.name}-${var.environment}"
  path  = "/"
  roles = ["${aws_iam_role.default_ecs_role.name}"]
}

output "arn" {
  value = "${aws_iam_role.default_ecs_role.arn}"
}

output "profile" {
  value = "${aws_iam_instance_profile.default_ecs.id}"
}

