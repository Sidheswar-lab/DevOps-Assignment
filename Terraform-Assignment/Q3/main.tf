terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = "eu-north-1"
}
resource "aws_iam_user" "q3_user" {
  name = "q3-terraform-user"

  tags = {
    Name = "q3-terraform-user"
  }
}
resource "aws_iam_user_policy_attachment" "administrator_access" {
  user       = aws_iam_user.q3_user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
resource "aws_iam_user_policy_attachment" "ec2_full_access" {
  user       = aws_iam_user.q3_user.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}
output "iam_user_name" {
  value = aws_iam_user.q3_user.name
}
output "iam_user_arn" {
  value = aws_iam_user.q3_user.arn
}
