/**
 * This module is used to set configuration defaults for the AWS infrastructure.
 * It doesn't provide much value when used on its own because terraform makes it
 * hard to do dynamic generations of things like subnets, for now it's used as
 * a helper module for the stack.
 *
 * Usage:
 *
 *     module "defaults" {
 *       source = "github.com/segmentio/stack/defaults"
 *       region = "us-east-1"
 *       cidr   = "10.0.0.0/16"
 *     }
 *
 */

variable "region" {
  description = "The AWS region"
}

variable "cidr" {
  description = "The CIDR block to provision for the VPC"
}

variable "default_ecs_ami" {
  default = {
    us-east-1      = "ami-5f3ff932"
    us-west-1      = "ami-31c08551"
    us-west-2      = "ami-f3985d93"
    eu-west-1      = "ami-ab4bd5d8"
    eu-central-1   = "ami-6c58b103"
    ap-northeast-1 = "ami-a69d68c7"
    ap-northeast-2 = "ami-7b2de615"
    ap-southeast-1 = "ami-550dde36"
    ap-southeast-2 = "ami-c799b0a4"
    sa-east-1      = "ami-0274fe6e"
  }
}

# http://docs.aws.amazon.com/ElasticLoadBalancing/latest/DeveloperGuide/enable-access-logs.html#attach-bucket-policy
variable "default_log_account_ids" {
  default = {
    us-east-1      = "127311923021"
    us-west-2      = "797873946194"
    us-west-1      = "027434742980"
    eu-west-1      = "156460612806"
    eu-central-1   = "054676820928"
    ap-southeast-1 = "114774131450"
    ap-northeast-1 = "582318560864"
    ap-southeast-2 = "783225319266"
    ap-northeast-2 = "600734575887"
    sa-east-1      = "507241528517"
    us-gov-west-1  = "048591011584"
    cn-north-1     = "638102146993"
  }
}

output "domain_name_servers" {
  value = "${cidrhost(var.cidr, 2)}"
}

output "ecs_ami" {
  value = "ami-5f3ff932"
}

output "s3_logs_account_id" {
  value = "127311923021"
}
