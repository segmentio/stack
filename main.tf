/**
 * The stack module combines sub modules to create a complete
 * stack with `vpc`, a default ecs cluster with auto scaling
 * and a bastion node that enables you to access all instances.
 *
 * Usage:
 *
 *    module "stack" {
 *      source      = "github.com/segmentio/stack"
 *      name        = "mystack"
 *      environment = "prod"
 *    }
 *
 */

variable "name" {
  description = "the name of your stack, e.g. \"segment\""
}

variable "environment" {
  description = "the name of your environment, e.g. \"prod-west\""
}

variable "key_name" {
  description = "the name of the ssh key to use, e.g. \"internal-key\""
}

variable "domain_name" {
  description = "the internal DNS name to use with services"
  default     = "stack.local"
}

variable "domain_name_servers" {
  description = "the internal DNS servers, defaults to the internal route53 server of the VPC"
  default     = ""
}

variable "region" {
  description = "the AWS region"
  default     = "us-west-2"
}

variable "cidr" {
  description = "the CIDR block to provision for the VPC"
  default     = "10.30.0.0/16"
}

variable "internal_subnets" {
  description = "a comma-separated list of CIDRs for internal subnets in your VPC"
  default     = "10.30.0.0/19,10.30.64.0/19,10.30.128.0/19"
}

variable "external_subnets" {
  description = "a comma-separated list of CIDRs for external subnets in your VPC"
  default     = "10.30.32.0/20,10.30.96.0/20,10.30.160.0/20"
}

variable "availability_zones" {
  description = "a comma-separated list of availability zones, defaults to all AZ of the region"
  default     = ""
}

variable "default_availability_zones" {
  description = "a mapping of the default availability zones for each AWS region"

  default = {
    us-east-1      = "us-east-1a,us-east-1b,us-east-1c,us-east-1e"
    us-west-1      = "us-west-1a,us-west-1b"
    us-west-2      = "us-west-2a,us-west-2b,us-west-2c"
    eu-west-1      = "eu-west-1a,eu-west-1b,eu-west-1c"
    eu-central-1   = "eu-central-1a,eu-central-1b"
    ap-southeast-1 = "ap-southeast-1a,ap-southeast-1b"
    ap-southeast-2 = "ap-southeast-2a,ap-southeast-2b,ap-southeast-2c"
    ap-northeast-1 = "ap-northeast-1a,ap-northeast-1c"
    ap-northeast-2 = "ap-northeast-2a,ap-northeast-2c"
    sa-east-1      = "sa-east-1a,sa-east-1b,sa-east-1c"
  }
}

variable "ecs_instance_type" {
  description = "the instance type to use for your default ecs cluster"
  default     = "m4.large"
}

variable "ecs_min_size" {
  description = "the minimum number of instances to use in the default ecs cluster"

  // create 3 instances in our cluster by default
  // 2 instances to run our service with high-availability
  // 1 extra instance so we can deploy without port collisions
  default = 3
}

variable "ecs_max_size" {
  description = "the maximum number of instances to use in the default ecs cluster"
  default     = 100
}

variable "ecs_desired_capacity" {
  description = "the desired number of instances to use in the default ecs cluster"
  default     = 3
}

variable "ecs_root_volume_size" {
  description = "the size of the ecs instance root volume"
  default     = 25
}

variable "ecs_docker_volume_size" {
  description = "the size of the ecs instance docker volume"
  default     = 25
}

variable "ecs_docker_auth_type" {
  description = "The docker auth type, see https://godoc.org/github.com/aws/amazon-ecs-agent/agent/engine/dockerauth for the possible values"
  default     = ""
}

variable "ecs_docker_auth_data" {
  description = "A JSON object providing the docker auth data, see https://godoc.org/github.com/aws/amazon-ecs-agent/agent/engine/dockerauth for the supported formats"
  default     = ""
}

variable "ecs_security_groups" {
  description = "A coma separated list of security groups from which ingest traffic will be allowed on the ECS cluster, it defaults to allowing ingress traffic on port 22 and coming grom the ELBs"
  default     = ""
}

variable "ecs_ami" {
  description = "The AMI that will be used to launch EC2 instances in the ECS cluster"
  default     = ""
}

variable "default_ecs_ami" {
  description = "A mapping of AWS regions to the default ECS AMIs"

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

module "vpc" {
  source             = "./vpc"
  name               = "${var.name}"
  cidr               = "${var.cidr}"
  internal_subnets   = "${var.internal_subnets}"
  external_subnets   = "${var.external_subnets}"
  availability_zones = "${coalesce(var.availability_zones, lookup(var.default_availability_zones, var.region))}"
  environment        = "${var.environment}"
}

module "security_groups" {
  source      = "./security-groups"
  name        = "${var.name}"
  vpc_id      = "${module.vpc.id}"
  environment = "${var.environment}"
  cidr        = "${var.cidr}"
}

module "bastion" {
  source          = "./bastion"
  region          = "${var.region}"
  security_groups = "${module.security_groups.external_ssh},${module.security_groups.internal_ssh}"
  vpc_id          = "${module.vpc.id}"
  subnet_id       = "${element(split(",",module.vpc.external_subnets), 0)}"
  key_name        = "${var.key_name}"
  environment     = "${var.environment}"
}

module "dhcp" {
  source  = "./dhcp"
  name    = "${module.dns.name}"
  vpc_id  = "${module.vpc.id}"
  servers = "${coalesce(var.domain_name_servers, cidrhost(var.cidr, 2))}"
}

module "dns" {
  source = "./dns"
  name   = "${var.domain_name}"
  vpc_id = "${module.vpc.id}"
}

module "iam_role" {
  source      = "./iam-role"
  name        = "${var.name}"
  environment = "${var.environment}"
}

module "ecs_cluster" {
  source               = "./ecs-cluster"
  name                 = "default"
  environment          = "${var.environment}"
  vpc_id               = "${module.vpc.id}"
  image_id             = "${coalesce(var.ecs_ami, lookup(var.default_ecs_ami, var.region))}"
  subnet_ids           = "${module.vpc.internal_subnets}"
  key_name             = "${var.key_name}"
  instance_type        = "${var.ecs_instance_type}"
  iam_instance_profile = "${module.iam_role.profile}"
  min_size             = "${var.ecs_min_size}"
  max_size             = "${var.ecs_max_size}"
  desired_capacity     = "${var.ecs_desired_capacity}"
  region               = "${var.region}"
  availability_zones   = "${var.availability_zones}"
  root_volume_size     = "${var.ecs_root_volume_size}"
  docker_volume_size   = "${var.ecs_docker_volume_size}"
  docker_auth_type     = "${var.ecs_docker_auth_type}"
  docker_auth_data     = "${var.ecs_docker_auth_data}"
  security_groups      = "${coalesce(var.ecs_security_groups, format("%s,%s,%s", module.security_groups.internal_ssh, module.security_groups.internal_elb, module.security_groups.external_elb))}"
}

module "s3_logs" {
  source      = "./s3-logs"
  name        = "${var.name}"
  environment = "${var.environment}"
  region      = "${var.region}"
}

// The region in which the infra lives.
output "region" {
  value = "${var.region}"
}

// The bastion host IP.
output "bastion_ip" {
  value = "${module.bastion.external_ip}"
}

// The internal route53 zone ID.
output "zone_id" {
  value = "${module.dns.zone_id}"
}

// Security group for internal ELBs.
output "internal_elb" {
  value = "${module.security_groups.internal_elb}"
}

// Security group for external ELBs.
output "external_elb" {
  value = "${module.security_groups.external_elb}"
}

// Comma separated list of internal subnet IDs.
output "internal_subnets" {
  value = "${module.vpc.internal_subnets}"
}

// Comma separated list of external subnet IDs.
output "external_subnets" {
  value = "${module.vpc.external_subnets}"
}

// ECS Service IAM role.
output "iam_role" {
  value = "${module.iam_role.arn}"
}

// S3 bucket ID for ELB logs.
output "log_bucket_id" {
  value = "${module.s3_logs.id}"
}

// The internal domain name, e.g "stack.local".
output "domain_name" {
  value = "${module.dns.name}"
}

// The environment of the stack, e.g "prod".
output "environment" {
  value = "${var.environment}"
}

// The default ECS cluster name.
output "cluster" {
  value = "${module.ecs_cluster.name}"
}

// The VPC availability zones.
output "availability_zones" {
  value = "${var.availability_zones}"
}

// The VPC security group ID.
output "vpc_security_group" {
  value = "${module.vpc.security_group}"
}

// The VPC ID.
output "vpc_id" {
  value = "${module.vpc.id}"
}

// The default ECS cluster security group ID.
output "ecs_cluster_security_group_id" {
  value = "${module.ecs_cluster.security_group_id}"
}
