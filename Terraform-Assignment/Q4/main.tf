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
data "aws_vpc" "default" {
  default = true
}
data "aws_subnet" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  availability_zone = "eu-north-1a"
}
data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
resource "aws_security_group" "q4_sg" {
  name        = "q4-security-group"
  description = "Security group for Q4"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "q4-security-group"
  }
}
resource "aws_instance" "q4_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  subnet_id = data.aws_subnet.default.id

  vpc_security_group_ids = [
    aws_security_group.q4_sg.id
  ]

  user_data = file("${path.module}/provision.sh")

  tags = {
    Name = "q4-nginx-server"
  }
}
output "instance_id" {
  value = aws_instance.q4_instance.id
}
output "public_ip" {
  value = aws_instance.q4_instance.public_ip
}
output "private_ip" {
  value = aws_instance.q4_instance.private_ip
}
