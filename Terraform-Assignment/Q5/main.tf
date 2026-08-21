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
variable "key_name" {
  default = "MyKey2"
}
variable "private_key_path" {
  default = "/home/sidheswar/DevOps/2341013023/MyKey2.pem"
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
    values = [
      "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
    ]
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
resource "aws_security_group" "q5_sg" {
  name        = "q5-security-group"
  description = "Security group for Q5"
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
    Name = "q5-security-group"
  }
}
resource "aws_instance" "backend" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id = data.aws_subnet.default.id
  key_name = var.key_name
  vpc_security_group_ids = [
    aws_security_group.q5_sg.id
  ]
  tags = {
    Name = "q5-backend"
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = self.public_ip
  }
  provisioner "file" {
    source      = "${path.module}/backend.sh"
    destination = "/tmp/backend.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/backend.sh",
      "sudo /tmp/backend.sh"
    ]
  }
}
resource "aws_instance" "frontend" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id = data.aws_subnet.default.id
  key_name = var.key_name
  vpc_security_group_ids = [
    aws_security_group.q5_sg.id
  ]
  tags = {
    Name = "q5-frontend"
  }
  depends_on = [
    aws_instance.backend
  ]
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = self.public_ip
  }
  provisioner "file" {
    content = templatefile("${path.module}/frontend.sh", {
      backend_public_ip = aws_instance.backend.public_ip
    })
    destination = "/tmp/frontend.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/frontend.sh",
      "sudo /tmp/frontend.sh"
    ]
  }
}
output "backend_instance_id" {
  value = aws_instance.backend.id
}
output "backend_public_ip" {
  value = aws_instance.backend.public_ip
}
output "frontend_instance_id" {
  value = aws_instance.frontend.id
}
output "frontend_public_ip" {
  value = aws_instance.frontend.public_ip
}
