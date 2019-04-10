variable "name" {
  description = "Load balancer name, e.g cdn"
}

variable "subnet_ids" {
  description = "Comma separated list of subnet IDs"
}

variable "environment" {
  description = "Environment tag, e.g prod"
}

variable "port" {
  description = "Instance port"
}

variable "security_groups" {
  description = "Comma separated list of security group IDs"
}

variable "healthcheck" {
  description = "Healthcheck path"
}

variable "log_bucket" {
  description = "S3 bucket name to write ALB logs into"
}

variable "external_dns_name" {
  description = "The subdomain under which the ALB is exposed externally, defaults to the task name"
}

variable "internal_dns_name" {
  description = "The subdomain under which the ALB is exposed internally, defaults to the task name"
}

variable "external_zone_id" {
  description = "The zone ID to create the record in"
}

variable "internal_zone_id" {
  description = "The zone ID to create the record in"
}

variable "ssl_certificate_id" {}

variable "vpc_id" {}

resource "aws_lb" "main" {
  name = "${var.name}"

  internal                         = false
  load_balancer_type               = "application"
  enable_cross_zone_load_balancing = true
  subnets                          = ["${split(",", var.subnet_ids)}"]
  security_groups                  = ["${split(",",var.security_groups)}"]

  idle_timeout = 30
  enable_http2 = true

  access_logs {
    bucket = "${var.log_bucket}"
  }

  tags {
    Name        = "${var.name}-balancer"
    Service     = "${var.name}"
    Environment = "${var.environment}"
  }
}

resource "aws_lb_target_group" "front_end" {
  depends_on = ["aws_lb.main"]

  name     = "${var.name}"
  port     = "${var.port}"
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    protocol            = "HTTP"
    port                = "${var.port}"
    path                = "${var.healthcheck}"
    interval            = 30
    matcher             = "200-299"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = "${aws_lb.main.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.front_end.arn}"
  }
}

resource "aws_lb_listener" "front_end_https" {
  load_balancer_arn = "${aws_lb.main.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${var.ssl_certificate_id}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.front_end.arn}"
  }
}

resource "aws_route53_record" "external" {
  zone_id = "${var.external_zone_id}"
  name    = "${var.external_dns_name}"
  type    = "A"

  alias {
    zone_id                = "${aws_lb.main.zone_id}"
    name                   = "${aws_lb.main.dns_name}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "internal" {
  zone_id = "${var.internal_zone_id}"
  name    = "${var.internal_dns_name}"
  type    = "A"

  alias {
    zone_id                = "${aws_lb.main.zone_id}"
    name                   = "${aws_lb.main.dns_name}"
    evaluate_target_health = false
  }
}

/**
 * Outputs.
 */

// The ALB name.
output "name" {
  value = "${aws_lb.main.name}"
}

// The ALB ID.
output "id" {
  value = "${aws_lb.main.id}"
}

// The ALB dns_name.
output "dns" {
  value = "${aws_lb.main.dns_name}"
}

// FQDN built using the zone domain and name (external)
output "external_fqdn" {
  value = "${aws_route53_record.external.fqdn}"
}

// FQDN built using the zone domain and name (internal)
output "internal_fqdn" {
  value = "${aws_route53_record.internal.fqdn}"
}

// The zone id of the ALB
output "zone_id" {
  value = "${aws_lb.main.zone_id}"
}

output "target_group_arn" {
  value = "${aws_lb_target_group.front_end.arn}"
}
