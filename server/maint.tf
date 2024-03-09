resource "aws_vpc" "vpc" {
  # Define your VPC configuration here
}

resource "aws_security_group" "name" {
  name        = "example-security-group"
  description = "Example security group for web server"

  vpc_id = aws_vpc.vpc.id

  // Inbound rules
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Outbound rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "example-security-group"
  }
}

resource "aws_instance" "web" {
  ami                    = var.ami
  instance_type          = var.size
#   subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_groups

  tags = {
    "Name"        = "Server from Module"
    "Environment" = "Training"
  }
}