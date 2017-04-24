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
  description = "the AWS region in which resources are created, you must set the availability_zones variable as well if you define this value to something other than the default"
  default     = "us-west-2"
}

variable "cidr" {
  description = "the CIDR block to provision for the VPC, if set to something other than the default, both internal_subnets and external_subnets have to be defined as well"
  default     = "10.30.0.0/16"
}

variable "internal_subnets" {
  description = "a list of CIDRs for internal subnets in your VPC, must be set if the cidr variable is defined, needs to have as many elements as there are availability zones"
  default     = ["10.30.0.0/19" ,"10.30.64.0/19", "10.30.128.0/19"]
}

variable "external_subnets" {
  description = "a list of CIDRs for external subnets in your VPC, must be set if the cidr variable is defined, needs to have as many elements as there are availability zones"
  default     = ["10.30.32.0/20", "10.30.96.0/20", "10.30.160.0/20"]
}

variable "availability_zones" {
  description = "a comma-separated list of availability zones, defaults to all AZ of the region, if set to something other than the defaults, both internal_subnets and external_subnets have to be defined as well"
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "bastion_instance_type" {
  description = "Instance type for the bastion"
  default = "t2.micro"
}

variable "ecs_cluster_name" {
  description = "the name of the cluster, if not specified the variable name will be used"
  default = ""
}

variable "ecs_instance_type" {
  description = "the instance type to use for your default ecs cluster"
  default     = "m4.large"
}

variable "ecs_instance_ebs_optimized" {
  description = "use EBS - not all instance types support EBS"
  default     = true
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
  description = "A comma separated list of security groups from which ingest traffic will be allowed on the ECS cluster, it defaults to allowing ingress traffic on port 22 and coming grom the ELBs"
  default     = ""
}

variable "ecs_ami" {
  description = "The AMI that will be used to launch EC2 instances in the ECS cluster"
  default     = ""
}

variable "extra_cloud_config_type" {
  description = "Extra cloud config type"
  default     = "text/cloud-config"
}

variable "extra_cloud_config_content" {
  description = "Extra cloud config content"
  default     = ""
}

variable "logs_expiration_enabled" {
  default = false
}

variable "logs_expiration_days" {
  default = 30
}

module "defaults" {
  source = "./defaults"
  region = "${var.region}"
  cidr   = "${var.cidr}"
}

module "vpc" {
  source             = "./vpc"
  name               = "${var.name}"
  cidr               = "${var.cidr}"
  internal_subnets   = "${var.internal_subnets}"
  external_subnets   = "${var.external_subnets}"
  availability_zones = "${var.availability_zones}"
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
  instance_type   = "${var.bastion_instance_type}"
  security_groups = "${module.security_groups.external_ssh},${module.security_groups.internal_ssh}"
  vpc_id          = "${module.vpc.id}"
  subnet_id       = "${element(module.vpc.external_subnets, 0)}"
  key_name        = "${var.key_name}"
  environment     = "${var.environment}"
}

module "dhcp" {
  source  = "./dhcp"
  name    = "${module.dns.name}"
  vpc_id  = "${module.vpc.id}"
  servers = "${coalesce(var.domain_name_servers, module.defaults.domain_name_servers)}"
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
  source                 = "./ecs-cluster"
  name                   = "${coalesce(var.ecs_cluster_name, var.name)}"
  environment            = "${var.environment}"
  vpc_id                 = "${module.vpc.id}"
  image_id               = "${coalesce(var.ecs_ami, module.defaults.ecs_ami)}"
  subnet_ids             = "${module.vpc.internal_subnets}"
  key_name               = "${var.key_name}"
  instance_type          = "${var.ecs_instance_type}"
  instance_ebs_optimized = "${var.ecs_instance_ebs_optimized}"
  iam_instance_profile   = "${module.iam_role.profile}"
  min_size               = "${var.ecs_min_size}"
  max_size               = "${var.ecs_max_size}"
  desired_capacity       = "${var.ecs_desired_capacity}"
  region                 = "${var.region}"
  availability_zones     = "${module.vpc.availability_zones}"
  root_volume_size       = "${var.ecs_root_volume_size}"
  docker_volume_size     = "${var.ecs_docker_volume_size}"
  docker_auth_type       = "${var.ecs_docker_auth_type}"
  docker_auth_data       = "${var.ecs_docker_auth_data}"
  security_groups        = "${coalesce(var.ecs_security_groups, format("%s,%s,%s", module.security_groups.internal_ssh, module.security_groups.internal_elb, module.security_groups.external_elb))}"
  extra_cloud_config_type     = "${var.extra_cloud_config_type}"
  extra_cloud_config_content  = "${var.extra_cloud_config_content}"
}

module "s3_logs" {
  source                  = "./s3-logs"
  name                    = "${var.name}"
  environment             = "${var.environment}"
  account_id              = "${module.defaults.s3_logs_account_id}"
  logs_expiration_enabled = "${var.logs_expiration_enabled}"
  logs_expiration_days    = "${var.logs_expiration_days}"
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

// Default ECS role ID. Useful if you want to add a new policy to that role.
output "iam_role_default_ecs_role_id" {
  value = "${module.iam_role.default_ecs_role_id}"
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
  value = "${module.vpc.availability_zones}"
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

// Comma separated list of internal route table IDs.
output "internal_route_tables" {
  value = "${module.vpc.internal_rtb_id}"
}

// The external route table ID.
output "external_route_tables" {
  value = "${module.vpc.external_rtb_id}"
}
