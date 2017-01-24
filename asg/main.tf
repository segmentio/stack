/**
 */

variable "name" {
  description = "The cluster name, e.g cdn"
}

variable "environment" {
  description = "Environment tag, e.g prod"
}

variable "vpc_id" {
  description = "VPC ID"
}

variable "image_id" {
  description = "AMI Image ID"
}

variable "subnet_ids" {
  description = "list of subnet IDs"
  type = "list"
}

variable "key_name" {
  description = "SSH key name to use"
}

variable "ingress_cidr" {
  description = "Comma separated list of ingress cidrs"
}

variable "iam_instance_profile" {
  description = "Instance profile ARN to use in the launch configuration"
}

variable "region" {
  description = "AWS Region"
}

variable "availability_zones" {
  description = "list of AZs"
  type = "list"
}

variable "instance_type" {
  description = "The instance type to use, e.g t2.small"
}

variable "instance_ebs_optimized" {
  description = "When set to true the instance will be launched with EBS optimized turned on"
  default     = true
}

variable "min_size" {
  description = "Minimum instance count"
  default     = 3
}

variable "max_size" {
  description = "Maxmimum instance count"
  default     = 100
}

variable "desired_capacity" {
  description = "Desired instance count"
  default     = 3
}

variable "associate_public_ip_address" {
  description = "Should created instances be publicly accessible (if the SG allows)"
  default     = false
}

variable "ebs_device_name" {
  default = "/dev/sdh"
}

variable "ebs_volume_type" {
  default = "standard"
}

variable "ebs_volume_size" {
  default = 1
}

variable "ebs_snapshot_id" {
  default = ""
}

variable "ebs_delete_on_termination" {
  default = true
}

variable "custom_script" {
  description = "Custom instance bootupt script"
  default     = ""
}

variable "load_balancers" {
  description = "ASG ELBs"
  default     = []
}

variable "health_check_grace_period" {
  description = "Time (in seconds) after instance comes into service before checking health"
  default     = 300
}

variable "target_group_arns" {
  description = "Application load balancer target group ARN(s)  if any"
  default     = []
}

variable "termination_policies" {
  description = "OldestInstance, NewestInstance, OldestLaunchConfiguration, ClosestToNextInstanceHour, Default"
  default     = ["OldestLaunchConfiguration", "Default"]
}

variable "wait_for_capacity_timeout" {
  description = "A maximum duration that Terraform should wait for ASG instances to be healthy before timing out"
  default     = "10m"
}

resource "aws_security_group" "asg" {
  name        = "${var.name}-asg"
  vpc_id      = "${var.vpc_id}"
  description = "Allows traffic from and to the EC2 instances of the ${var.name} ASG"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["${split(",", var.ingress_cidr)}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "ASG (${var.name})"
    Environment = "${var.environment}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "template_file" "instance_config" {
  template = "${file("${path.module}/files/instance-config.yml.tpl")}"

  vars {
    custom_script = "${var.custom_script}"
  }
}

resource "aws_launch_configuration" "main" {
  name_prefix = "${format("%s-", var.name)}"

  image_id                    = "${var.image_id}"
  instance_type               = "${var.instance_type}"
  ebs_optimized               = "${var.instance_ebs_optimized}"
  iam_instance_profile        = "${var.iam_instance_profile}"
  key_name                    = "${var.key_name}"
  security_groups             = ["${aws_security_group.asg.id}"]
  user_data                   = "${template_file.instance_config.rendered}"
  associate_public_ip_address = "${var.associate_public_ip_address}"

  # spot_price                  = "0.07"

  # root
  ebs_block_device {
    device_name           = "${var.ebs_device_name}"
    volume_type           = "${var.ebs_volume_type}"
    volume_size           = "${var.ebs_volume_size}"
    snapshot_id           = "${var.ebs_snapshot_id}"
    delete_on_termination = "${var.ebs_delete_on_termination}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "main" {
  name = "${var.name}"

  availability_zones        = ["${var.availability_zones}"]
  vpc_zone_identifier       = ["${var.subnet_ids}"]
  launch_configuration      = "${aws_launch_configuration.main.id}"
  min_size                  = "${var.min_size}"
  max_size                  = "${var.max_size}"
  desired_capacity          = "${var.desired_capacity}"
  health_check_grace_period = "${var.health_check_grace_period}"
  health_check_type         = "ELB"
  load_balancers            = ["${var.load_balancers}"]
  target_group_arns         = ["${var.target_group_arns}"]
  termination_policies      = "${var.termination_policies}"
  wait_for_capacity_timeout = "${var.wait_for_capacity_timeout}"

  tag {
    key                 = "Name"
    value               = "${var.name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Cluster"
    value               = "${var.name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "${var.environment}"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.name}-scaleup"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.main.name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.name}-scaledown"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.main.name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.name}-cpureservation-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "60"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.main.name}"
  }

  alarm_description = "Scale up if the cpu reservation is above 60% for 10 minutes"
  alarm_actions     = ["${aws_autoscaling_policy.scale_up.arn}"]

  lifecycle {
    create_before_destroy = true
  }

  # This is required to make cloudwatch alarms creation sequential, AWS doesn't
  # support modifying alarms concurrently.
  depends_on = ["aws_autoscaling_group.main"]
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.name}-cpureservation-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "10"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.main.name}"
  }

  alarm_description = "Scale down if the cpu reservation is below 10% for 10 minutes"
  alarm_actions     = ["${aws_autoscaling_policy.scale_down.arn}"]

  lifecycle {
    create_before_destroy = true
  }

  # This is required to make cloudwatch alarms creation sequential, AWS doesn't
  # support modifying alarms concurrently.
  depends_on = ["aws_cloudwatch_metric_alarm.cpu_high"]
}

// The asg name, e.g cdn
output "name" {
  value = "${var.name}"
}

// The asg security group ID.
output "security_group_id" {
  value = "${aws_security_group.asg.id}"
}