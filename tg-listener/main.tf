/**
 * The tg-listener module creates an target group, and 2 listener rules
 * It is used by the service-tg module.
 */

/**
* Required Variables.
*/
variable "name" {
  description = "target group name, e.g cdn"
}

variable "port" {
  description = "Instance port"
}

variable "protocol" {
  description = "Protocol to use, HTTP or TCP"
  default = "HTTP"
}

variable "vpc_id" {
  description = "The ID of the VPC in which your targets are located"
}

variable "tags" {
  description = "tags for the distribution"
  type        = "map"
  description = "tags, just tags"
}

variable "listener_arn_80" {
  description = "arn of an aws_alb_listener"
  type = "string"
}

variable "priority" {
  description = "The priority for the rule. A listener can't have multiple rules with the same priority"
}

variable "condition_values" {
  description = "This should include the service name and the environment, there must be no trailing period (.); omit the root domain. For example: community.dev"
  type = "string"
}

variable "listener_arn_443" {
  description = "arn of an aws_alb_listener"
  type = "string"
}

/**
 * Options.
 */
variable "health_check_protocol" {
  description = "The protocol that the load balancer uses when performing health checks on the targets. Accepts HTTP, HTTPS "
  type = "string"
  default = "HTTP"
}

variable "health_check_path" {
  description = "The ping path destination where Elastic Load Balancing sends health check requests"
  type = "string"
  default = "/"
}

variable "health_check_port" {
  description = "The port to use to connect with the target. Valid values are either ports 1-65536, or traffic-port"
  type = "string"
  default = "traffic-port"
}

variable "health_check_healthy_threshold" {
  description = "The number of consecutive successful health checks that are required before an unhealthy target is considered healthy"
  default = 2
}

variable "health_check_unhealthy_threshold" {
  description = " The number of consecutive failed health checks that are required before a target is considered unhealthy"
  default = 2
}

variable "health_check_timeout" {
  description = "The number of seconds to wait for a response before considering that a health check has failed"
  default = 5
}

variable "health_check_interval" {
  description = "The approximate number of seconds between health checks for an individual target"
  default = 30
}

variable "health_check_matcher" {
  description = "The HTTP codes that a healthy target uses when responding to a health check. HTTP codes must be in Matcher data type"
  type = "string"
  default = "200-399"
}

variable "condition_field" {
  description = "The name of the field. Must be one of path-pattern for path based routing or host-header for host based routing. Accepts path-pattern, host-header"
  type = "string"
  default = "host-header"
}

/**
 * Resources.
 */

 module "tf-aws-alb-target-group-bdcloud" {
   source                           = "github.com/BuildDirect/tf-modules//tf-aws-alb-target-group?ref=0.1.13"
   name                             = "${var.name}-tg"
   port                             = "${var.port}"
   protocol                         = "${var.protocol}"
   vpc_id                           = "${var.vpc_id}"
   health_check_protocol            = "${var.health_check_protocol}"
   health_check_path                = "${var.health_check_path}"
   health_check_port                = "${var.health_check_port}"
   health_check_healthy_threshold   = "${var.health_check_healthy_threshold}"
   health_check_unhealthy_threshold = "${var.health_check_unhealthy_threshold}"
   health_check_timeout             = "${var.health_check_timeout}"
   health_check_interval            = "${var.health_check_interval}"
   health_check_matcher             = "${var.health_check_matcher}"
   tags                             = "${var.tags}"
 }

 module "tf-aws-alb-listener-rule-80" {
   source                  = "github.com/BuildDirect/tf-modules//tf-aws-alb-listener-rule?ref=0.1.11"
   listener_arn            = "${var.listener_arn_80}"
   priority                = "${var.priority}"
   action_target_group_arn = "${module.tf-aws-alb-target-group-bdcloud.alb_target_group_arn}"
   condition_field         = "${var.condition_field}"
   condition_values        = "${var.condition_values}.bdcloud.ca"
 }

 module "tf-aws-alb-listener-rule-443" {
   source                  = "github.com/BuildDirect/tf-modules//tf-aws-alb-listener-rule?ref=0.1.11"
   listener_arn            = "${var.listener_arn_443}"
   priority                = "${var.priority}"
   action_target_group_arn = "${module.tf-aws-alb-target-group-bdcloud.alb_target_group_arn}"
   condition_field         = "${var.condition_field}"
   condition_values        = "${var.condition_values}.bdcloud.ca"
 }

/**
 * Outputs.
 */

 //The name for the target group for tg bdcloud.ca
 output "name" {
   value = "${module.tf-aws-alb-target-group-bdcloud.alb_target_group_name}"
 }

 //The arn for the target group for tg bdcloud.ca
 output "arn" {
   value = "${module.tf-aws-alb-target-group-bdcloud.alb_target_group_arn}"
 }
