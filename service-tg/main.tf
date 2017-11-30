/**
 * The web-service is similar to the `service` module, but the
 * it provides a tg-listner rule instead.
 *
 * Usage:
 *
 *      module "auth_service" {
 *        source    = "github.com/segmentio/stack/service"
 *        name      = "auth-service"
 *        image     = "auth-service"
 *        cluster   = "default"
 *      }
 *
 */

/**
 * Required Variables.
 */

variable "environment" {
  description = "Environment tag, e.g prod"
}

variable "image" {
  description = "The docker image name, e.g nginx"
}

variable "name" {
  description = "The service name, if empty the service name is defaulted to the image name"
  default     = ""
}

variable "protocol" {
  description = "Protocol to use, HTTP or TCP"
  default = "HTTP"
}

variable "version" {
  description = "The docker image version"
  default     = "latest"
}

variable "subnet_ids" {
  description = "Comma separated list of subnet IDs that will be passed to the tg-listner module"
}

variable "security_groups" {
  description = "Comma separated list of security group IDs that will be passed to the tg-listner module"
}

variable "port" {
  description = "The container host port"
}

variable "cluster" {
  description = "The cluster name or ARN"
}

variable "log_bucket" {
  description = "The S3 bucket ID to use for the tg-listner"
}

variable "iam_role" {
  description = "IAM Role ARN to use"
}

/**
 * Options.
 */

variable "healthcheck" {
  description = "Path to a healthcheck endpoint"
  default     = "/"
}

variable "container_port" {
  description = "The container port"
  default     = 3000
}

variable "command" {
  description = "The raw json of the task command"
  default     = "[]"
}

variable "env_vars" {
  description = "The raw json of the task env vars"
  default     = "[]"
}

variable "desired_count" {
  description = "The desired count"
  default     = 2
}

variable "memory" {
  description = "The number of MiB of memory to reserve for the container"
  default     = 512
}

variable "cpu" {
  description = "The number of cpu units to reserve for the container"
  default     = 512
}

variable "deployment_minimum_healthy_percent" {
  description = "lower limit (% of desired_count) of # of running tasks during a deployment"
  default     = 100
}

variable "deployment_maximum_percent" {
  description = "upper limit (% of desired_count) of # of running tasks during a deployment"
  default     = 200
}

variable "vpc_id" {
  description = "The id of the VPC."
}

variable "health_check_protocol" {
  description = "The protocol that the load balancer uses when performing health checks on the targets. Accepts HTTP, HTTPS "
  type = "string"
  default = "HTTP"
}
variable "health_check_path" {
  description = "The ping path destination where Elastic Load Balancing sends health check requests"
  type = "string"
  default = "/api/Heartbeats"
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

variable "tags" {
  description = "tags for the distribution"
  type        = "map"
  description = "tags, just tags"
}

//additional listener specific vars
variable "priority" {
  description = "The priority for the rule. A listener can't have multiple rules with the same priority"
}

variable "condition_field" {
  description = "The name of the field. Must be one of path-pattern for path based routing or host-header for host based routing. Accepts path-pattern, host-header"
  type = "string"
  default = "host-header"
}

variable "condition_values" {
  description = "This should include the service name and the environment, there must be no trailing period (.); omit the root domain. For example: community.dev"
  type = "string"
}

variable "listener_arn_80" {
  description = "arn of an aws_alb_listener"
  type = "string"
}

variable "listener_arn_443" {
  description = "arn of an aws_alb_listener"
  type = "string"
}

/**
 * Resources.
 */

resource "aws_ecs_service" "main" {
  name                               = "${module.task.name}"
  cluster                            = "${var.cluster}"
  task_definition                    = "${module.task.arn}"
  desired_count                      = "${var.desired_count}"
  iam_role                           = "${var.iam_role}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"
  deployment_maximum_percent         = "${var.deployment_maximum_percent}"
  depends_on                         = ["module.tg-listner"]

  load_balancer {
    target_group_arn = "${module.tg-listner.arn}"
    container_name   = "${module.task.name}"
    container_port   = "${var.container_port}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

module "task" {
  source = "../task"

  name              = "${coalesce(var.name, replace(var.image, "/", "-"))}"
  image             = "${var.image}"
  image_version     = "${var.version}"
  command           = "${var.command}"
  env_vars          = "${var.env_vars}"
  memory            = "${var.memory}"
  cpu               = "${var.cpu}"

  ports = <<EOF
  [
    {
      "containerPort": ${var.container_port},
      "hostPort": ${var.port}
    }
  ]
EOF
}

module "tg-listner" {
  source = "../tg-listner"

  name                             = "${module.task.name}"
  environment                      = "${var.environment}"
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
  priority                         = "${var.priority}"
  condition_field                  = "${var.condition_field}"
  condition_values                 = "${var.condition_values}"
  tags                             = "${var.tags}"
  listener_arn_80                  = "${var.listener_arn_80}"
  listener_arn_443                 = "${var.listener_arn_443}"
}

/**
 * Outputs.
 */

// The name of the tg-listner
output "name" {
  value = "${module.tg-listner.name}"
}

// The arn of the tg-listner
output "arn" {
  value = "${module.tg-listner.arn}"
}
