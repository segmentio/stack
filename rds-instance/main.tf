variable "name" { }

variable "zone_id" { }

variable "dns_name" { }

variable "environment" { }

variable "database_username" { }

variable "database_password" { }

variable "vpc_id" { }

variable "allocated_storage" {
  default = "50"
}

variable "engine_version" {
  default = "9.5.4"
}

variable "instance_type" {
  default = "db.t2.small"
}

variable "storage_type" {
  default = "gp2"
}

variable "database_port" {
  default = "5432"
}

variable "backup_retention_period" {
  default = "30"
}

variable "backup_window" {
  # 12:00AM-12:30AM ET
  default = "04:00-04:30"
}

variable "maintenance_window" {
  # SUN 12:30AM-01:30AM ET
  default = "sun:04:30-sun:05:30"
}

variable "auto_minor_version_upgrade" {
  default = true
}

variable "multi_availability_zone" {
  # multi AZ runs extra standby instance, so paying for double
  default = false
}

variable "storage_encrypted" {
  default = false
}

variable "publicly_accessible" {
  default = false
}

variable "parameter_group" {
  default = "default.postgres9.5"
}

variable "security_groups" {
  description = "A list of security group IDs"
  type = "list"
}

variable "subnet_ids" {
  description = "A list of subnet IDs"
  type = "list"
}

resource "aws_security_group" "main" {
  name        = "${var.name}-rds-instance"
  description = "Allows traffic to rds from other security groups"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port       = "${var.database_port}"
    to_port         = "${var.database_port}"
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
    Name        = "RDS instance (${var.name})"
    Environment = "${var.environment}"
  }
}

resource "aws_db_subnet_group" "main" {
  name        = "${var.name}"
  description = "RDS cluster subnet group"
  subnet_ids  = ["${var.subnet_ids}"]
}

resource "aws_db_instance" "main" {
  allocated_storage       = "${var.allocated_storage}"
  engine                  = "postgres"
  engine_version          = "${var.engine_version}"
  identifier              = "postgres"
  instance_class          = "${var.instance_type}"
  storage_type            = "${var.storage_type}"
  name                    = "${var.name}"
  password                = "${var.database_password}"
  username                = "${var.database_username}"
  backup_retention_period = "${var.backup_retention_period}"
  backup_window           = "${var.backup_window}"
  maintenance_window      = "${var.maintenance_window}"
  multi_az                = "${var.multi_availability_zone}"
  port                    = "${var.database_port}"
  storage_encrypted       = "${var.storage_encrypted}"
  db_subnet_group_name    = "${aws_db_subnet_group.main.name}"
  publicly_accessible     = "${var.publicly_accessible}"

  tags {
    Name        = "postgresql"
    Environment = "${var.environment}"
  }
}

resource "aws_route53_record" "main" {
  zone_id = "${var.zone_id}"
  name    = "${coalesce(var.dns_name, var.name)}"
  type    = "CNAME"
  ttl     = 300
  records = ["${aws_db_instance.main.endpoint}"]
}

output "id" {
  value = "${aws_db_instance.main.id}"
}

output "endpoint" {
  value = "${aws_db_instance.main.endpoint}"
}

output "fqdn" {
  value = "${aws_route53_record.main.fqdn}"
}

output "port" {
  value = "${aws_db_instance.main.port}"
}
