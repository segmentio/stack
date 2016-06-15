/**
 * The module creates an IAM user.
 *
 * Usage:
 *
 *    module "my_user" {
 *      name = "user"
 *      policy = <<EOF
 *      {}
 *    EOF
 *    }
 *
 */

variable "name" {
  description = "The user name, e.g my-user"
}

variable "policy" {
  description = "The raw json policy"
}

/**
 * IAM User.
 */

resource "aws_iam_user" "main" {
  name = "${var.name}"

  lifecycle {
    create_before_destroy = true
  }
}

/**
 * Access Key.
 */

resource "aws_iam_access_key" "main" {
  user = "${aws_iam_user.main.name}"

  lifecycle {
    create_before_destroy = true
  }
}

/**
 * Policy.
 */

resource "aws_iam_user_policy" "main" {
  name   = "${var.name}"
  user   = "${aws_iam_user.main.name}"
  policy = "${var.policy}"

  lifecycle {
    create_before_destroy = true
  }
}

/**
 * Outputs.
 */

// The aws access key id.
output "access_key" {
  value = "${aws_iam_access_key.main.id}"
}

// The aws secret access key.
output "secret_key" {
  value = "${aws_iam_access_key.main.secret}"
}

// The user ARN
output "arn" {
  value = "${aws_iam_user.main.arn}"
}
