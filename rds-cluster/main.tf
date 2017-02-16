variable "name" {
  description = "The name will be used to prefix and tag the resources, e.g mydb"
}

variable "environment" {
  description = "The environment tag, e.g prod"
}

variable "vpc_id" {
  description = "The VPC ID to use"
}

variable "zone_id" {
  description = "The Route53 Zone ID where the DNS record will be created"
}

variable "security_groups" {
  description = "A list of security group IDs"
  type        = "list"
}

variable "subnet_ids" {
  description = "A list of subnet IDs"
  type        = "list"
}

variable "availability_zones" {
  description = "A list of availability zones"
  type        = "list"
}

variable "database_name" {
  description = "The database name"
}

variable "master_username" {
  description = "The master user username"
}

variable "master_password" {
  description = "The master user password"
}

variable "instance_type" {
  description = "The type of instances that the RDS cluster will be running on"
  default     = "db.r3.large"
}

variable "instance_count" {
  description = "How many instances will be provisioned in the RDS cluster"
  default     = 1
}

variable "preferred_backup_window" {
  description = "The time window on which backups will be made (HH:mm-HH:mm)"
  default     = "07:00-09:00"
}

variable "backup_retention_period" {
  description = "The backup retention period"
  default     = 5
}

variable "publicly_accessible" {
  description = "When set to true the RDS cluster can be reached from outside the VPC"
  default     = false
}

variable "dns_name" {
  description = "Route53 record name for the RDS database, defaults to the database name if not set"
  default     = ""
}

variable "port" {
  description = "The port at which the database listens for incoming connections"
  default     = 3306
}

variable "skip_final_snapshot" {
  description = "When set to false deletion will be delayed to take a snapshot from which the database can be recovered"
  default     = true
}

resource "aws_security_group" "main" {
  name        = "${var.name}-rds-cluster"
  description = "Allows traffic to rds from other security groups"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port       = "${var.port}"
    to_port         = "${var.port}"
    protocol        = "TCP"
    security_groups = ["${var.security_groups}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "RDS cluster (${var.name})"
    Environment = "${var.environment}"
  }
}

resource "aws_db_subnet_group" "main" {
  name        = "${var.name}"
  description = "RDS cluster subnet group"
  subnet_ids  = ["${var.subnet_ids}"]
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count                = "${var.instance_count}"
  db_subnet_group_name = "${aws_db_subnet_group.main.id}"
  cluster_identifier   = "${aws_rds_cluster.main.id}"
  publicly_accessible  = "${var.publicly_accessible}"
  instance_class       = "${var.instance_type}"

  # need a deterministic identifier or terraform will force a new resource every apply
  identifier = "${aws_rds_cluster.main.id}-${count.index}"
}

resource "aws_rds_cluster" "main" {
  cluster_identifier        = "${var.name}"
  availability_zones        = ["${var.availability_zones}"]
  database_name             = "${var.database_name}"
  master_username           = "${var.master_username}"
  master_password           = "${var.master_password}"
  backup_retention_period   = "${var.backup_retention_period}"
  preferred_backup_window   = "${var.preferred_backup_window}"
  vpc_security_group_ids    = ["${aws_security_group.main.id}"]
  db_subnet_group_name      = "${aws_db_subnet_group.main.id}"
  port                      = "${var.port}"
  skip_final_snapshot       = "${var.skip_final_snapshot}"
  final_snapshot_identifier = "${var.name}-finalsnapshot"
}

resource "aws_route53_record" "main" {
  zone_id = "${var.zone_id}"
  name    = "${coalesce(var.dns_name, var.name)}"
  type    = "CNAME"
  ttl     = 300
  records = ["${aws_rds_cluster.main.endpoint}"]
}

// The cluster identifier.
output "id" {
  value = "${aws_rds_cluster.main.id}"
}

output "endpoint" {
  value = "${aws_rds_cluster.main.endpoint}"
}

output "fqdn" {
  value = "${aws_route53_record.main.fqdn}"
}

output "port" {
  value = "${aws_rds_cluster.main.port}"
}
