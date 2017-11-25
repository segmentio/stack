/**
 * The web-service is similar to the `service` module, but the
 * it provides a __public__ ALB instead.
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

variable "version" {
  description = "The docker image version"
  default     = "latest"
}

variable "subnet_ids" {
  description = "Comma separated list of subnet IDs that will be passed to the ALB module"
}

variable "security_groups" {
  description = "Comma separated list of security group IDs that will be passed to the ALB module"
}

variable "port" {
  description = "The container host port"
}

variable "cluster" {
  description = "The cluster name or ARN"
}

variable "log_bucket" {
  description = "The S3 bucket ID to use for the ALB"
}

variable "ssl_certificate_id" {
  description = "SSL Certificate ID to use"
}

variable "iam_role" {
  description = "IAM Role ARN to use"
}

variable "external_dns_name" {
  description = "The subdomain under which the ALB is exposed externally, defaults to the task name"
  default     = ""
}

variable "internal_dns_name" {
  description = "The subdomain under which the ALB is exposed internally, defaults to the task name"
  default     = ""
}

variable "external_zone_id" {
  description = "The zone ID to create the record in"
}

variable "internal_zone_id" {
  description = "The zone ID to create the record in"
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
  depends_on                         = ["module.alb"]

  load_balancer {
    target_group_arn = "${module.alb.target_group}"
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

module "alb" {
  source = "../alb"

  name               = "${module.task.name}"
  port               = "${var.port}"
  environment        = "${var.environment}"
  subnet_ids         = "${var.subnet_ids}"
  external_dns_name  = "${coalesce(var.external_dns_name, module.task.name)}"
  internal_dns_name  = "${coalesce(var.internal_dns_name, module.task.name)}"
  healthcheck        = "${var.healthcheck}"
  external_zone_id   = "${var.external_zone_id}"
  internal_zone_id   = "${var.internal_zone_id}"
  security_groups    = "${var.security_groups}"
  log_bucket         = "${var.log_bucket}"
  ssl_certificate_id = "${var.ssl_certificate_id}"
  vpc_id             = "${var.vpc_id}"
}

/**
 * Outputs.
 */

// The name of the ALB
output "name" {
  value = "${module.alb.name}"
}

// The DNS name of the ALB
output "dns" {
  value = "${module.alb.dns}"
}

// The id of the ALB
output "alb" {
  value = "${module.alb.id}"
}

// The zone id of the ALB
output "zone_id" {
  value = "${module.alb.zone_id}"
}

// FQDN built using the zone domain and name (external)
output "external_fqdn" {
  value = "${module.alb.external_fqdn}"
}

// FQDN built using the zone domain and name (internal)
output "internal_fqdn" {
  value = "${module.alb.internal_fqdn}"
}
