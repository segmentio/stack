variable "docker_image" {}

resource "aws_ecr_repository" "image" {
  name = "${var.docker_image}"
}

resource "aws_ecr_repository_policy" "default" {
  repository = "${aws_ecr_repository.image.name}"
  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "public permissions",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability"
            ]
        }
    ]
}
EOF
}

output "repository_url" {
  value = "${aws_ecr_repository.image.repository_url}"
}
