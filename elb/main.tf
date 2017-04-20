/**
 * The ELB module creates an ELB, security group
 * a route53 record and a service healthcheck.
 * It is used by the service module.
 */

variable "name" {
  description = "ELB name, e.g cdn"
  type = "string"
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type = "list"
}

variable "environment" {
  description = "Environment tag, e.g prod"
  type = "string"
}

variable "port" {
  description = "Instance port"
  type = "string"
}

variable "security_groups" {
  description = "List of security group IDs"
  type = "list"
}

variable "dns_name" {
  description = "Route53 record name"
  type = "string"
}

variable "healthcheck" {
  description = "Healthcheck path"
  type = "string"
}

variable "healthcheck_healthy_threshold" {
  description = "Number of consecutive health check successes before declaring an EC2 instance healthy."
  default     = 2
}

variable "healthcheck_unhealthy_threshold" {
  description = "Number of consecutive health check failures before declaring an EC2 instance unhealthy."
  default     = 2
}

variable "healthcheck_timeout" {
  description = "Time to wait when receiving a response from the health check (2 sec  60 sec)."
  default     = 5
}

variable "healthcheck_interval" {
  description = "Amount of time between health checks (5 sec  300 sec)"
  default     = 30
}

variable "protocol" {
  description = "Protocol to use, HTTP or TCP"
  type = "string"
}

variable "zone_id" {
  description = "Route53 zone ID to use for dns_name"
  type = "string"
}

variable "log_bucket" {
  description = "S3 bucket name to write ELB logs into"
  type = "string"
}

# https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/config-idle-timeout.html?icmpid=docs_elb_console
variable "idle_timeout" {
  description = "ELB idle connection timeout"
  default     = 30
}

/**
 * Resources.
 */

resource "aws_elb" "main" {
  name = "${var.name}"

  internal                  = true
  cross_zone_load_balancing = true
  subnets                   = ["${var.subnet_ids}"]
  security_groups           = ["${var.security_groups}"]

  idle_timeout                = "${var.idle_timeout}"
  connection_draining         = true
  connection_draining_timeout = 15

  listener {
    lb_port           = "${var.port}"
    lb_protocol       = "${var.protocol}"
    instance_port     = "${var.port}"
    instance_protocol = "${var.protocol}"
  }

  health_check {
    healthy_threshold   = "${var.healthcheck_healthy_threshold}"
    unhealthy_threshold = "${var.healthcheck_unhealthy_threshold}"
    timeout             = "${var.healthcheck_timeout}"
    target              = "${var.protocol}:${var.port}${var.healthcheck}"
    interval            = "${var.healthcheck_interval}"
  }

  access_logs {
    bucket = "${var.log_bucket}"
  }

  tags {
    Name        = "${var.name}-balancer"
    Service     = "${var.name}"
    Environment = "${var.environment}"
  }
}

resource "aws_route53_record" "main" {
  zone_id = "${var.zone_id}"
  name    = "${var.dns_name}"
  type    = "A"

  alias {
    name                   = "${aws_elb.main.dns_name}"
    zone_id                = "${aws_elb.main.zone_id}"
    evaluate_target_health = false
  }
}

/**
 * Outputs.
 */

// Instance port
output "port" {
  value = "${var.port}"
}

// The ELB name.
output "name" {
  value = "${aws_elb.main.name}"
}

// The ELB ID.
output "id" {
  value = "${aws_elb.main.id}"
}

// The ELB dns_name.
output "dns" {
  value = "${aws_elb.main.dns_name}"
}

// FQDN built using the zone domain and name
output "fqdn" {
  value = "${aws_route53_record.main.fqdn}"
}

// The zone id of the ELB
output "zone_id" {
  value = "${aws_elb.main.zone_id}"
}

