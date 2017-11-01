# Stack

The stack module combines sub modules to create a complete
stack with `vpc`, a default ecs cluster with auto scaling
and a bastion node that enables you to access all instances.

Usage:

    module "stack" {
      source      = "github.com/segmentio/stack"
      name        = "mystack"
      environment = "prod"
    }

## Available Modules

* [stack](#stack)
* [bastion](#bastion)
* [defaults](#defaults)
* [dhcp](#dhcp)
* [dns](#dns)
* [ecs-cluster](#ecs-cluster)
* [elb](#elb)
* [iam-user](#iam-user)
* [rds-cluster](#rds-cluster)
* [s3-logs](#s3-logs)
* [security-groups](#security-groups)
* [service](#service)
* [task](#task)
* [vpc](#vpc)
* [web-service](#web-service)
* [worker](#worker)

## Inputs

| Name | Description | Default | Required |
|------|-------------|:-----:|:-----:|
| name | the name of your stack, e.g. "segment" | - | yes |
| environment | the name of your environment, e.g. "prod-west" | - | yes |
| key_name | the name of the ssh key to use, e.g. "internal-key" | - | yes |
| domain_name | the internal DNS name to use with services | `stack.local` | no |
| domain_name_servers | the internal DNS servers, defaults to the internal route53 server of the VPC | `` | no |
| region | the AWS region in which resources are created, you must set the availability_zones variable as well if you define this value to something other than the default | `us-west-2` | no |
| cidr | the CIDR block to provision for the VPC, if set to something other than the default, both internal_subnets and external_subnets have to be defined as well | `10.30.0.0/16` | no |
| internal_subnets | a list of CIDRs for internal subnets in your VPC, must be set if the cidr variable is defined, needs to have as many elements as there are availability zones | `<list>` | no |
| external_subnets | a list of CIDRs for external subnets in your VPC, must be set if the cidr variable is defined, needs to have as many elements as there are availability zones | `<list>` | no |
| use_nat_instances | use NAT EC2 instances instead of the NAT gateway service | `false` | no |
| use_eip_with_nat_instances | use Elastic IPs with NAT instances if `use_nat_instances` is true | `false` | no |
| nat_instance_type | the EC2 instance type for NAT instances if `use_nat_instances` is true | `t2.nano` | no |
| nat_instance_ssh_key_name | the name of the ssh key to use with NAT instances if `use_nat_instances` is true | "" | no |
| availability_zones | a comma-separated list of availability zones, defaults to all AZ of the region, if set to something other than the defaults, both internal_subnets and external_subnets have to be defined as well | `<list>` | no |
| bastion_instance_type | Instance type for the bastion | `t2.micro` | no |
| ecs_cluster_name | the name of the cluster, if not specified the variable name will be used | `` | no |
| ecs_instance_type | the instance type to use for your default ecs cluster | `m4.large` | no |
| ecs_instance_ebs_optimized | use EBS - not all instance types support EBS | `true` | no |
| ecs_min_size | the minimum number of instances to use in the default ecs cluster | `3` | no |
| ecs_max_size | the maximum number of instances to use in the default ecs cluster | `100` | no |
| ecs_desired_capacity | the desired number of instances to use in the default ecs cluster | `3` | no |
| ecs_root_volume_size | the size of the ecs instance root volume | `25` | no |
| ecs_docker_volume_size | the size of the ecs instance docker volume | `25` | no |
| ecs_docker_auth_type | The docker auth type, see https://godoc.org/github.com/aws/amazon-ecs-agent/agent/engine/dockerauth for the possible values | `` | no |
| ecs_docker_auth_data | A JSON object providing the docker auth data, see https://godoc.org/github.com/aws/amazon-ecs-agent/agent/engine/dockerauth for the supported formats | `` | no |
| ecs_security_groups | A comma separated list of security groups from which ingest traffic will be allowed on the ECS cluster, it defaults to allowing ingress traffic on port 22 and coming from the ELBs | `` | no |
| ecs_ami | The AMI that will be used to launch EC2 instances in the ECS cluster | `` | no |
| extra_cloud_config_type | Extra cloud config type | `text/cloud-config` | no |
| extra_cloud_config_content | Extra cloud config content | `` | no |

## Outputs

| Name | Description |
|------|-------------|
| region | The region in which the infra lives. |
| bastion_ip | The bastion host IP. |
| zone_id | The internal route53 zone ID. |
| internal_elb | Security group for internal ELBs. |
| external_elb | Security group for external ELBs. |
| internal_subnets | Comma separated list of internal subnet IDs. |
| external_subnets | Comma separated list of external subnet IDs. |
| iam_role | ECS Service IAM role. |
| iam_role_default_ecs_role_id | Default ECS role ID. Useful if you want to add a new policy to that role. |
| log_bucket_id | S3 bucket ID for ELB logs. |
| domain_name | The internal domain name, e.g "stack.local". |
| environment | The environment of the stack, e.g "prod". |
| cluster | The default ECS cluster name. |
| availability_zones | The VPC availability zones. |
| vpc_security_group | The VPC security group ID. |
| vpc_id | The VPC ID. |
| ecs_cluster_security_group_id | The default ECS cluster security group ID. |
| internal_route_tables | Comma separated list of internal route table IDs. |
| external_route_tables | The external route table ID. |

# bastion

The bastion host acts as the "jump point" for the rest of the infrastructure.
Since most of our instances aren't exposed to the external internet, the bastion acts as the gatekeeper for any direct SSH access.
The bastion is provisioned using the key name that you pass to the stack (and hopefully have stored somewhere).
If you ever need to access an instance directly, you can do it by "jumping through" the bastion.

   $ terraform output # print the bastion ip
   $ ssh -i <path/to/key> ubuntu@<bastion-ip> ssh ubuntu@<internal-ip>

Usage:

    module "bastion" {
      source            = "github.com/segmentio/stack/bastion"
      region            = "us-west-2"
      security_groups   = "sg-1,sg-2"
      vpc_id            = "vpc-12"
      key_name          = "ssh-key"
      subnet_id         = "pub-1"
      environment       = "prod"
    }



## Inputs

| Name | Description | Default | Required |
|------|-------------|:-----:|:-----:|
| instance_type | Instance type, see a list at: https://aws.amazon.com/ec2/instance-types/ | `t2.micro` | no |
| region | AWS Region, e.g us-west-2 | - | yes |
| security_groups | a comma separated lists of security group IDs | - | yes |
| vpc_id | VPC ID | - | yes |
| key_name | The SSH key pair, key name | - | yes |
| subnet_id | A external subnet id | - | yes |
| environment | Environment tag, e.g prod | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| external_ip | Bastion external IP address. |

# defaults

This module is used to set configuration defaults for the AWS infrastructure.
It doesn't provide much value when used on its own because terraform makes it
hard to do dynamic generations of things like subnets, for now it's used as
a helper module for the stack.

Usage:

    module "defaults" {
      source = "github.com/segmentio/stack/defaults"
      region = "us-east-1"
      cidr   = "10.0.0.0/16"
    }



## Inputs

| Name | Description | Default | Required |
|------|-------------|:-----:|:-----:|
| region | The AWS region | - | yes |
| cidr | The CIDR block to provision for the VPC | - | yes |
| default_ecs_ami |  | `<map>` | no |
| default_log_account_ids | # http://docs.aws.amazon.com/ElasticLoadBalancing/latest/DeveloperGuide/enable-access-logs.html#attach-bucket-policy | `<map>` | no |

## Outputs

| Name | Description |
|------|-------------|
| domain_name_servers |  |
| ecs_ami |  |
| s3_logs_account_id |  |

# dhcp


## Inputs

| Name | Description | Default | Required |
|------|-------------|:-----:|:-----:|
| name | The domain name to setup DHCP for | - | yes |
| vpc_id | The ID of the VPC to setup DHCP for | - | yes |
| servers | A comma separated list of the IP addresses of internal DHCP servers | - | yes |

# dns

The dns module creates a local route53 zone that serves
as a service discovery utility. For example a service
resource with the name `auth` and a dns module
with the name `stack.local`, the service address will be `auth.stack.local`.

Usage:

    module "dns" {
      source = "github.com/segment/stack"
      name   = "stack.local"
    }



## Inputs

| Name | Description | Default | Required |
|------|-------------|:-----:|:-----:|
| name | Zone name, e.g stack.local | - | yes |
| vpc_id | The VPC ID (omit to create a public zone) | `` | no |

## Outputs

| Name | Description |
|------|-------------|
| name | The domain name. |
| zone_id | The zone ID. |
| name_servers | A comma separated list of the zone name servers. |

# ecs-cluster

ECS Cluster creates a cluster with the following features:

 - Autoscaling groups
 - Instance tags for filtering
 - EBS volume for docker resources


Usage:

     module "cdn" {
       source               = "github.com/segmentio/stack/ecs-cluster"
       environment          = "prod"
       name                 = "cdn"
       vpc_id               = "vpc-id"
       image_id             = "ami-id"
       subnet_ids           = ["1" ,"2"]
       key_name             = "ssh-key"
       security_groups      = "1,2"
       iam_instance_profile = "id"
       region               = "us-west-2"
       availability_zones   = ["a", "b"]
       instance_type        = "t2.small"
     }



## Inputs

| Name | Description | Default | Required |
|------|-------------|:-----:|:-----:|
| name | The cluster name, e.g cdn | - | yes |
| environment | Environment tag, e.g prod | - | yes |
| vpc_id | VPC ID | - | yes |
| image_id | AMI Image ID | - | yes |
| subnet_ids | List of subnet IDs | - | yes |
| key_name | SSH key name to use | - | yes |
| security_groups | Comma separated list of security groups | - | yes |
| iam_instance_profile | Instance profile ARN to use in the launch configuration | - | yes |
| region | AWS Region | - | yes |
| availability_zones | List of AZs | - | yes |
| instance_type | The instance type to use, e.g t2.small | - | yes |
| instance_ebs_optimized | When set to true the instance will be launched with EBS optimized turned on | `true` | no |
| min_size | Minimum instance count | `3` | no |
| max_size | Maxmimum instance count | `100` | no |
| desired_capacity | Desired instance count | `3` | no |
| associate_public_ip_address | Should created instances be publicly accessible (if the SG allows) | `false` | no |
| root_volume_size | Root volume size in GB | `25` | no |
| docker_volume_size | Attached EBS volume size in GB | `25` | no |
| docker_auth_type | The docker auth type, see https://godoc.org/github.com/aws/amazon-ecs-agent/agent/engine/dockerauth for the possible values | `` | no |
| docker_auth_data | A JSON object providing the docker auth data, see https://godoc.org/github.com/aws/amazon-ecs-agent/agent/engine/dockerauth for the supported formats | `` | no |
| extra_cloud_config_type | Extra cloud config type | `text/cloud-config` | no |
| extra_cloud_config_content | Extra cloud config content | `` | no |

## Outputs

| Name | Description |
|------|-------------|
| name | The cluster name, e.g cdn |
| security_group_id | The cluster security group ID. |

# elb

The ELB module creates an ELB, security group
a route53 record and a service healthcheck.
It is used by the service module.


## Inputs

| Name | Description | Default | Required |
|------|-------------|:-----:|:-----:|
| name | ELB name, e.g cdn | - | yes |
| subnet_ids | Comma separated list of subnet IDs | - | yes |
| environment | Environment tag, e.g prod | - | yes |
| port | Instance port | - | yes |
| security_groups | Comma separated list of security group IDs | - | yes |
| dns_name | Route53 record name | - | yes |
| healthcheck | Healthcheck path | - | yes |
| protocol | Protocol to use, HTTP or TCP | - | yes |
| zone_id | Route53 zone ID to use for dns_name | - | yes |
| log_bucket | S3 bucket name to write ELB logs into | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| name | The ELB name. |
| id | The ELB ID. |
| dns | The ELB dns_name. |
| fqdn | FQDN built using the zone domain and name |
| zone_id | The zone id of the ELB |

# iam-user

The module creates an IAM user.

Usage:

    module "my_user" {
      name = "user"
      policy = <<EOF
      {}
    EOF
    }



## Inputs

| Name | Description | Default | Required |
|------|-------------|:-----:|:-----:|
| name | The user name, e.g my-user | - | yes |
| policy | The raw json policy | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| access_key | The aws access key id. |
| secret_key | The aws secret access key. |
| arn | The user ARN |

# rds-cluster


## Inputs

| Name | Description | Default | Required |
|------|-------------|:-----:|:-----:|
| name | The name will be used to prefix and tag the resources, e.g mydb | - | yes |
| environment | The environment tag, e.g prod | - | yes |
| vpc_id | The VPC ID to use | - | yes |
| zone_id | The Route53 Zone ID where the DNS record will be created | - | yes |
| security_groups | A list of security group IDs | - | yes |
| subnet_ids | A list of subnet IDs | - | yes |
| availability_zones | A list of availability zones | - | yes |
| database_name | The database name | - | yes |
| master_username | The master user username | - | yes |
| master_password | The master user password | - | yes |
| instance_type | The type of instances that the RDS cluster will be running on | `db.r3.large` | no |
| instance_count | How many instances will be provisioned in the RDS cluster | `1` | no |
| preferred_backup_window | The time window on which backups will be made (HH:mm-HH:mm) | `07:00-09:00` | no |
| backup_retention_period | The backup retention period | `5` | no |
| publicly_accessible | When set to true the RDS cluster can be reached from outside the VPC | `false` | no |
| dns_name | Route53 record name for the RDS database, defaults to the database name if not set | `` | no |
| port | The port at which the database listens for incoming connections | `3306` | no |
| skip_final_snapshot | When set to false deletion will be delayed to take a snapshot from which the database can be recovered | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The cluster identifier. |
| endpoint |  |
| fqdn |  |
| port |  |

# s3-logs


## Inputs

| Name | Description | Default | Required |
|------|-------------|:-----:|:-----:|
| name |  | - | yes |
| environment |  | - | yes |
| account_id |  | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| id |  |

# security-groups

Creates basic security groups to be used by instances and ELBs.


## Inputs

| Name | Description | Default | Required |
|------|-------------|:-----:|:-----:|
| name | The name of the security groups serves as a prefix, e.g stack | - | yes |
| vpc_id | The VPC ID | - | yes |
| environment | The environment, used for tagging, e.g prod | - | yes |
| cidr | The cidr block to use for internal security groups | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| external_ssh | External SSH allows ssh connections on port 22 from the world. |
| internal_ssh | Internal SSH allows ssh connections from the external ssh security group. |
| internal_elb | Internal ELB allows internal traffic. |
| external_elb | External ELB allows traffic from the world. |

# service

The service module creates an ecs service, task definition
elb and a route53 record under the local service zone (see the dns module).

Usage:

     module "auth_service" {
       source    = "github.com/segmentio/stack/service"
       name      = "auth-service"
       image     = "auth-service"
       cluster   = "default"
     }



## Inputs

| Name | Description | Default | Required |
|------|-------------|:-----:|:-----:|
| environment | Environment tag, e.g prod | - | yes |
| image | The docker image name, e.g nginx | - | yes |
| name | The service name, if empty the service name is defaulted to the image name | `` | no |
| version | The docker image version | `latest` | no |
| subnet_ids | Comma separated list of subnet IDs that will be passed to the ELB module | - | yes |
| security_groups | Comma separated list of security group IDs that will be passed to the ELB module | - | yes |
| port | The container host port | - | yes |
| cluster | The cluster name or ARN | - | yes |
| dns_name | The DNS name to use, e.g nginx | - | yes |
| log_bucket | The S3 bucket ID to use for the ELB | - | yes |
| healthcheck | Path to a healthcheck endpoint | `/` | no |
| container_port | The container port | `3000` | no |
| command | The raw json of the task command | `[]` | no |
| env_vars | The raw json of the task env vars | `[]` | no |
| desired_count | The desired count | `2` | no |
| memory | The number of MiB of memory to reserve for the container | `512` | no |
| cpu | The number of cpu units to reserve for the container | `512` | no |
| protocol | The ELB protocol, HTTP or TCP | `HTTP` | no |
| iam_role | IAM Role ARN to use | - | yes |
| zone_id | The zone ID to create the record in | - | yes |
| deployment_minimum_healthy_percent | lower limit (% of desired_count) of # of running tasks during a deployment | `100` | no |
| deployment_maximum_percent | upper limit (% of desired_count) of # of running tasks during a deployment | `200` | no |

## Outputs

| Name | Description |
|------|-------------|
| name | The name of the ELB |
| dns | The DNS name of the ELB |
| elb | The id of the ELB |
| zone_id | The zone id of the ELB |
| fqdn | FQDN built using the zone domain and name |

# task

The task module creates an ECS task definition.

Usage:

    module "nginx" {
      source = "github.com/segmentio/stack/task"
      name   = "nginx"
      image  = "nginx"
    }



## Inputs

| Name | Description | Default | Required |
|------|-------------|:-----:|:-----:|
| image | The docker image name, e.g nginx | - | yes |
| name | The worker name, if empty the service name is defaulted to the image name | - | yes |
| cpu | The number of cpu units to reserve for the container | `512` | no |
| env_vars | The raw json of the task env vars | `[]` | no |
| command | The raw json of the task command | `[]` | no |
| entry_point | The docker container entry point | `[]` | no |
| ports | The docker container ports | `[]` | no |
| image_version | The docker image version | `latest` | no |
| memory | The number of MiB of memory to reserve for the container | `512` | no |

## Outputs

| Name | Description |
|------|-------------|
| name | The created task definition name |
| arn | The created task definition ARN |

# vpc


## Inputs

| Name | Description | Default | Required |
|------|-------------|:-----:|:-----:|
| cidr | The CIDR block for the VPC. | - | yes |
| external_subnets | List of external subnets | - | yes |
| internal_subnets | List of internal subnets | - | yes |
| environment | Environment tag, e.g prod | - | yes |
| availability_zones | List of availability zones | - | yes |
| name | Name tag, e.g stack | `stack` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The VPC ID |
| external_subnets | A comma-separated list of subnet IDs. |
| internal_subnets | A list of subnet IDs. |
| security_group | The default VPC security group ID. |
| availability_zones | The list of availability zones of the VPC. |
| internal_rtb_id | The internal route table ID. |
| external_rtb_id | The external route table ID. |
| internal_nat_ips | The list of EIPs associated with the internal subnets. |

# web-service

The web-service is similar to the `service` module, but the
it provides a __public__ ELB instead.

Usage:

     module "auth_service" {
       source    = "github.com/segmentio/stack/service"
       name      = "auth-service"
       image     = "auth-service"
       cluster   = "default"
     }



## Inputs

| Name | Description | Default | Required |
|------|-------------|:-----:|:-----:|
| environment | Environment tag, e.g prod | - | yes |
| image | The docker image name, e.g nginx | - | yes |
| name | The service name, if empty the service name is defaulted to the image name | `` | no |
| version | The docker image version | `latest` | no |
| subnet_ids | Comma separated list of subnet IDs that will be passed to the ELB module | - | yes |
| security_groups | Comma separated list of security group IDs that will be passed to the ELB module | - | yes |
| port | The container host port | - | yes |
| cluster | The cluster name or ARN | - | yes |
| log_bucket | The S3 bucket ID to use for the ELB | - | yes |
| ssl_certificate_id | SSL Certificate ID to use | - | yes |
| iam_role | IAM Role ARN to use | - | yes |
| external_dns_name | The subdomain under which the ELB is exposed externally, defaults to the task name | `` | no |
| internal_dns_name | The subdomain under which the ELB is exposed internally, defaults to the task name | `` | no |
| external_zone_id | The zone ID to create the record in | - | yes |
| internal_zone_id | The zone ID to create the record in | - | yes |
| healthcheck | Path to a healthcheck endpoint | `/` | no |
| container_port | The container port | `3000` | no |
| command | The raw json of the task command | `[]` | no |
| env_vars | The raw json of the task env vars | `[]` | no |
| desired_count | The desired count | `2` | no |
| memory | The number of MiB of memory to reserve for the container | `512` | no |
| cpu | The number of cpu units to reserve for the container | `512` | no |
| deployment_minimum_healthy_percent | lower limit (% of desired_count) of # of running tasks during a deployment | `100` | no |
| deployment_maximum_percent | upper limit (% of desired_count) of # of running tasks during a deployment | `200` | no |

## Outputs

| Name | Description |
|------|-------------|
| name | The name of the ELB |
| dns | The DNS name of the ELB |
| elb | The id of the ELB |
| zone_id | The zone id of the ELB |
| external_fqdn | FQDN built using the zone domain and name (external) |
| internal_fqdn | FQDN built using the zone domain and name (internal) |

# worker

The worker module creates an ECS service that has no ELB attached.

Usage:

    module "my_worker" {
      source       = "github.com/segmentio/stack"
      environment  = "prod"
      name         = "worker"
      image        = "worker"
      cluster      = "default"
    }



## Inputs

| Name | Description | Default | Required |
|------|-------------|:-----:|:-----:|
| environment | Environment tag, e.g prod | - | yes |
| image | The docker image name, e.g nginx | - | yes |
| name | The worker name, if empty the service name is defaulted to the image name | `` | no |
| version | The docker image version | `latest` | no |
| cluster | The cluster name or ARN | - | yes |
| command | The raw json of the task command | `[]` | no |
| env_vars | The raw json of the task env vars | `[]` | no |
| desired_count | The desired count | `1` | no |
| memory | The number of MiB of memory to reserve for the container | `512` | no |
| cpu | The number of cpu units to reserve for the container | `512` | no |
| deployment_minimum_healthy_percent | lower limit (% of desired_count) of # of running tasks during a deployment | `100` | no |
| deployment_maximum_percent | upper limit (% of desired_count) of # of running tasks during a deployment | `200` | no |
