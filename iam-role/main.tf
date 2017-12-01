variable "name" {
  description = "The name of the stack to use in security groups"
}

variable "environment" {
  description = "The name of the environment for this stack"
}

resource "aws_iam_role" "default_ecs_role" {
  name = "ecs-role-${var.name}-${var.environment}"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "ecs.amazonaws.com",
          "ec2.amazonaws.com"
        ]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "default_ecs_service_role_policy" {
  name = "ecs-service-role-policy-${var.name}-${var.environment}"
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
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:RegisterTargets"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "default_ecs_instance_role_policy" {
  name = "ecs-instance-role-policy-${var.name}-${var.environment}"
  role = "${aws_iam_role.default_ecs_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecs:StartTask",
        "autoscaling:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "default_ecs" {
  name  = "ecs-instance-profile-${var.name}-${var.environment}"
  path  = "/"
  roles = ["${aws_iam_role.default_ecs_role.name}"]
}

output "default_ecs_role_id" {
  value = "${aws_iam_role.default_ecs_role.id}"
}

output "arn" {
  value = "${aws_iam_role.default_ecs_role.arn}"
}

output "profile" {
  value = "${aws_iam_instance_profile.default_ecs.id}"
}
