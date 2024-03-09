provider "aws" {
  region = var.region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] // Canonical owner ID
}

resource "aws_subnet" "public_subnets" {
  for_each                = var.subnet_cidr_blocks
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value   # Replace with your desired CIDR block
  availability_zone       = "us-east-1a" # Replace with your desired availability zone
  map_public_ip_on_launch = true         # Set to true if you want instances in this subnet to have public IP addresses
  tags = {
    Name = each.key
  }
}

resource "aws_security_group" "vpc-ping" {
  name        = "vpc-ping"
  description = "Security group for ICMP traffic within VPC"

  vpc_id = aws_vpc.vpc.id

  // Define inbound and outbound rules as needed
  // For example, allowing ICMP traffic within the VPC:
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/16"] # Update with your VPC CIDR block
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ingress-ssh" {
  name        = "ingress-ssh"
  description = "Security group for ssh"

  vpc_id = aws_vpc.vpc.id

  // Define inbound and outbound rules as needed
  // For example, allowing ICMP traffic within the VPC:
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Update with your VPC CIDR block
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "vpc-web" {
  name        = "vpc-web"
  description = "Security group for web servers"

  vpc_id = aws_vpc.vpc.id

  // Define inbound and outbound rules as needed for web servers
  // For example, allowing HTTP traffic (TCP port 80) from anywhere:
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Update with your VPC CIDR block or specific IP ranges
  }

  // Define egress rules as needed for web servers
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16" # Update with your desired VPC CIDR block

  tags = {
    Name = "MyVPC"
  }
}



module "server" {
  source    = "./server"
  ami       = data.aws_ami.ubuntu.id
  # subnet_id = aws_subnet.public_subnets["public_subnet_3"].id
  security_groups = [
    aws_security_group.vpc-ping.id,
    aws_security_group.ingress-ssh.id,
    aws_security_group.vpc-web.id
  ]
}

# module "server_2" {
#   source    = "./server"
#   ami       = data.aws_ami.ubuntu.id
#   subnet_id = aws_subnet.public_subnets["public_subnet_3"].id
#   security_groups = [
#     aws_security_group.vpc-ping.id,
#     aws_security_group.ingress-ssh.id,
#     aws_security_group.vpc-web.id
#   ]
# }

variable "subnet_cidr_blocks" {
  type = map(string)
  default = {
    public_subnet_1 = "10.0.1.0/24"
    public_subnet_2 = "10.0.2.0/24"
    public_subnet_3 = "10.0.3.0/24"
    # Add more subnets as needed
  }
}

variable "region" {
  default = "us-east-1"
}

output "size" {
  value = module.server.public_ip
}