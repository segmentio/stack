variable "cidr" {
  description = "The CIDR block for the VPC."
}

variable "external_subnets" {
  description = "Comma separated list of subnets"
}

variable "internal_subnets" {
  description = "Comma separated list of subnets"
}

variable "environment" {
  description = "Environment tag, e.g prod"
}

variable "availability_zones" {
  description = "Comma separated list of availability zones"
}

variable "name" {
  description = "Name tag, e.g stack"
  default     = "stack"
}

/**
 * VPC
 */

resource "aws_vpc" "main" {
  cidr_block           = "${var.cidr}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name        = "${var.name}"
    Environment = "${var.environment}"
  }
}

/**
 * Gateways
 */

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name        = "${var.name}"
    Environment = "${var.environment}"
  }
}

resource "aws_nat_gateway" "main" {
  count         = "${length(compact(split(",", var.internal_subnets)))}"
  allocation_id = "${element(aws_eip.nat.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.external.*.id, count.index)}"
  depends_on    = ["aws_internet_gateway.main"]
}

resource "aws_eip" "nat" {
  count = "${length(compact(split(",", var.internal_subnets)))}"
  vpc   = true
}

/**
 * Subnets.
 */

resource "aws_subnet" "internal" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${element(split(",", var.internal_subnets), count.index)}"
  availability_zone = "${element(split(",", var.availability_zones), count.index)}"
  count             = "${length(compact(split(",", var.internal_subnets)))}"

  tags {
    Name = "${var.name}-${format("internal-%03d", count.index+1)}"
  }
}

resource "aws_subnet" "external" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${element(split(",", var.external_subnets), count.index)}"
  availability_zone       = "${element(split(",", var.availability_zones), count.index)}"
  count                   = "${length(compact(split(",", var.external_subnets)))}"
  map_public_ip_on_launch = true

  tags {
    Name = "${var.name}-${format("external-%03d", count.index+1)}"
  }
}

/**
 * Route tables
 */

resource "aws_route_table" "external" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "${var.name}-external-001"
  }
}

resource "aws_route" "external" {
  route_table_id         = "${aws_route_table.external.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.main.id}"
}

resource "aws_route_table" "internal" {
  count  = "${length(compact(split(",", var.internal_subnets)))}"
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "${var.name}-${format("internal-%03d", count.index+1)}"
  }
}

resource "aws_route" "internal" {
  count                  = "${length(compact(split(",", var.internal_subnets)))}"
  route_table_id         = "${element(aws_route_table.internal.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.main.*.id, count.index)}"
}

/**
 * Route associations
 */

 /**
  * Route associations removed from vpc sub-sub module. moved to tf-stack\vpc-changes.tf. see CO-854

  *resource "aws_route_table_association" "internal" {
  *  count          = "${length(compact(split(",", var.internal_subnets)))}"
  *  subnet_id      = "${element(aws_subnet.internal.*.id, count.index)}"
  *  route_table_id = "${element(aws_route_table.internal.*.id, count.index)}"
  *}

  *resource "aws_route_table_association" "external" {
  *  count          = "${length(compact(split(",", var.external_subnets)))}"
  *  subnet_id      = "${element(aws_subnet.external.*.id, count.index)}"
  *  route_table_id = "${aws_route_table.external.id}"
  *}

*/


/**
 * Outputs
 */

// The VPC ID
output "id" {
  value = "${aws_vpc.main.id}"
}

// A comma-separated list of subnet IDs.
output "external_subnets" {
  value = "${join(",", aws_subnet.external.*.id)}"
}

// A comma-separated list of subnet IDs.
output "internal_subnets" {
  value = "${join(",", aws_subnet.internal.*.id)}"
}

// The default VPC security group ID.
output "security_group" {
  value = "${aws_vpc.main.default_security_group_id}"
}

// The list of availability zones of the VPC.
output "availability_zones" {
  value = "${join(",", aws_subnet.external.*.availability_zone)}"
}

// The internal route table ID.
output "internal_rtb_id" {
  value = "${join(",", aws_route_table.internal.*.id)}"
}

// The external route table ID.
output "external_rtb_id" {
  value = "${aws_route_table.external.id}"
}