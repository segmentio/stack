variable "name" {
  description = "The name will be used to prefix and tag the resources, e.g mydb"
}

variable "environment" {
  description = "The environment tag, e.g prod"
}

variable "vpc_id" {
  description = "The VPC ID to use"
}

variable "security_groups" {
  description = "A comma-separated list of security group IDs"
}

variable "subnet_ids" {
  description = "A comma-separated list of subnet IDs"
}

variable "availability_zones" {
  description = "A comma-separated list of availability zones"
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

resource "aws_security_group" "main" {
  name        = "${var.name}-rds-cluster"
  description = "Allows traffic to rds from other security groups"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "TCP"
    security_groups = ["${split(",", var.security_groups)}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name        = "RDS cluster (${var.name})"
    Environment = "${var.environment}"
  }
}

resource "aws_db_subnet_group" "main" {
  name        = "${var.name}"
  description = "rds cluster subnet group"
  subnet_ids  = ["${split(",", var.subnet_ids)}"]
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count                = 1
  db_subnet_group_name = "${aws_db_subnet_group.main.id}"
  cluster_identifier   = "${aws_rds_cluster.main.id}"
  publicly_accessible  = "${var.publicly_accessible}"
  instance_class       = "${var.instance_type}"
}

resource "aws_rds_cluster" "main" {
  cluster_identifier      = "${var.name}"
  availability_zones      = ["${split(",", var.availability_zones)}"]
  database_name           = "${var.database_name}"
  master_username         = "${var.master_username}"
  master_password         = "${var.master_password}"
  backup_retention_period = "${var.backup_retention_period}"
  preferred_backup_window = "${var.preferred_backup_window}"
  vpc_security_group_ids  = ["${aws_security_group.main.id}"]
  db_subnet_group_name    = "${aws_db_subnet_group.main.id}"
}

// The cluster identifier.
output "id" {
  value = "${aws_rds_cluster.main.id}"
}

// The address of the rds instance.
output "address" {
  value = "${aws_rds_cluster.main.address}"
}
