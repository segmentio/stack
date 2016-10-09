variable "name" {
}

variable "environment" {
}

variable "account_id" {
}

data "template_file" "policy" {
  template = "${file("${path.module}/policy.json")}"

  vars = {
    bucket     = "${var.name}-${var.environment}-logs"
    account_id = "${var.account_id}"
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "${var.name}-${var.environment}-logs"

  tags {
    Name        = "${var.name}-${var.environment}-logs"
    Environment = "${var.environment}"
  }

  policy = "${data.template_file.policy.rendered}"
}

output "id" {
  value = "${aws_s3_bucket.logs.id}"
}
