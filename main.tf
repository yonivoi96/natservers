provider "aws" {
  region = "eu-north-1"
}

resource "aws_vpc" "nats_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_route_table" "nats_route_table" {
  vpc_id = aws_vpc.nats_vpc.id
}

resource "aws_internet_gateway" "nats_gateway" {
  vpc_id = aws_vpc.nats_vpc.id
}

resource "aws_route" "internet_gateway_route" {
  route_table_id         = aws_route_table.nats_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.nats_gateway.id
}

resource "aws_route_table_association" "nats_association" {
  subnet_id      = aws_subnet.nats_subnet.id
  route_table_id = aws_route_table.nats_route_table.id
}

resource "aws_subnet" "nats_subnet" {
  vpc_id            = aws_vpc.nats_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "eu-north-1a"
}

resource "aws_security_group" "nats_sg" {
  vpc_id = aws_vpc.nats_vpc.id

  ingress {
    from_port   = 4222
    to_port     = 4222
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 6222
    to_port   = 6222
    protocol  = "tcp"
    self      = true
  }
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 4248
    to_port     = 4248
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5248
    to_port     = 5248
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 6248
    to_port     = 6248
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "tf-key-pair" {
  key_name   = "tf-key-pair"
  public_key = tls_private_key.rsa.public_key_openssh
}
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "local_file" "tf-key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "tf-key-pair"
}

resource "aws_instance" "nats_server" {
  count                       = 3
  ami                         = "ami-065681da47fb4e433"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.nats_subnet.id
  security_groups             = [aws_security_group.nats_sg.id]
  associate_public_ip_address = true
  key_name                    = "tf-key-pair"

  tags = {
    Name = "nats-server-${count.index + 1}"
  }

  user_data = <<-EOF
              #!/bin/bash
              wget -O archive.zip https://github.com/nats-io/nats-server/releases/download/v2.6.0/nats-server-v2.6.0-linux-amd64.zip
              unzip archive.zip
              chmod +x nats-server-v2.6.0-linux-amd64/nats-server
              sudo mv nats-server-v2.6.0-linux-amd64/nats-server /usr/bin
              EOF
}
