terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }

  required_version = ">= 1.0"
}

provider "aws" {
  region = "eu-north-1"
}

resource "aws_vpc" "q1_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "q1-vpc"
  }
}

resource "aws_subnet" "q1_subnet" {
  vpc_id                  = aws_vpc.q1_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "q1-subnet"
  }
}

resource "aws_internet_gateway" "q1_igw" {
  vpc_id = aws_vpc.q1_vpc.id

  tags = {
    Name = "q1-igw"
  }
}

resource "aws_route_table" "q1_route_table" {
  vpc_id = aws_vpc.q1_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.q1_igw.id
  }

  tags = {
    Name = "q1-route-table"
  }
}

resource "aws_route_table_association" "q1_association" {
  subnet_id      = aws_subnet.q1_subnet.id
  route_table_id = aws_route_table.q1_route_table.id
}

resource "aws_security_group" "q1_sg" {
  name        = "q1-security-group"
  description = "Security group for Q1 EC2"
  vpc_id      = aws_vpc.q1_vpc.id

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
    Name = "q1-security-group"
  }
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

resource "aws_instance" "q1_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  subnet_id = aws_subnet.q1_subnet.id

  vpc_security_group_ids = [
    aws_security_group.q1_sg.id
  ]

  tags = {
    Name = "q1-ec2-instance"
  }
}

output "vpc_id" {
  value = aws_vpc.q1_vpc.id
}

output "subnet_id" {
  value = aws_subnet.q1_subnet.id
}

output "route_table_id" {
  value = aws_route_table.q1_route_table.id
}

output "instance_id" {
  value = aws_instance.q1_instance.id
}

output "public_ip" {
  value = aws_instance.q1_instance.public_ip
}
