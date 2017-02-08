variable "name" {
  description = "RDS name and Postgres username"
}

variable "engine" {
  description = "Database engine: mysql, postgres, etc."
  default     = "postgres"
}

variable "engine_version" {
  description = "Database version"
  default     = "9.6.1"
}

variable "port" {
  description = "Port for database to listen on"
  default     = 5432
}

variable "password" {
  description = "Postgres user password"
}

variable "multi_az" {
  description = "If true, database will be placed in multiple AZs for HA"
  default     = false
}

variable "backup_retention_period" {
  description = "Backup retention, in days"
  default     = 5
}

variable "backup_window" {
  description = "Time window for backups."
  default     = "00:00-01:00"
}

variable "maintenance_window" {
  description = "Time window for maintenance."
  default     = "Mon:01:00-Mon:02:00"
}

variable "apply_immediately" {
  description = "If false, apply changes during maintenance window"
  default     = true
}

variable "instance_class" {
  description = "Underlying instance type"
  default     = "db.t2.micro"
}

variable "storage_type" {
  description = "Storage type: standard, gp2, or io1"
  default     = "gp2"
}

variable "allocated_storage" {
  description = "Disk size, in GB"
  default     = 10
}

variable "publicly_accessible" {
  description = "If true, the RDS instance will be open to the internet"
  default     = false
}

variable "vpc_id" {
  description = "The VPC ID to use"
}

variable "security_groups" {
  description = "A list of security group IDs"
  type        = "list"
}

variable "subnet_ids" {
  description = "A list of subnet IDs"
  type        = "list"
}

resource "aws_security_group" "main" {
  name        = "${var.name}-rds"
  description = "Allows traffic to RDS from other security groups"
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
    Name = "RDS (${var.name})"
  }
}

resource "aws_db_subnet_group" "main" {
  name        = "${var.name}"
  description = "RDS subnet group"
  subnet_ids  = ["${var.subnet_ids}"]
}

resource "aws_db_instance" "main" {
  identifier = "${var.name}"

  # Database
  engine         = "${var.engine}"
  engine_version = "${var.engine_version}"
  username       = "${var.name}"
  password       = "${var.password}"
  multi_az       = "${var.multi_az}"
  name           = "${var.name}"

  # Backups / maintenance
  backup_retention_period = "${var.backup_retention_period}"
  backup_window           = "${var.backup_window}"
  maintenance_window      = "${var.maintenance_window}"
  apply_immediately       = "${var.apply_immediately}"

  # Hardware
  instance_class    = "${var.instance_class}"
  storage_type      = "${var.storage_type}"
  allocated_storage = "${var.allocated_storage}"

  # Network / security
  db_subnet_group_name   = "${aws_db_subnet_group.main.id}"
  vpc_security_group_ids = ["${aws_security_group.main.id}"]
  publicly_accessible    = "${var.publicly_accessible}"
}

output "addr" {
  value = "postgres://${aws_db_instance.main.username}:${aws_db_instance.main.password}@${aws_db_instance.main.endpoint}"
}
