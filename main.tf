provider "aws" {
  region = "eu-north-1"
}

resource "aws_vpc" "nats_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
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
}

resource "aws_instance" "nats_server" {
  count                       = 3
  ami                         = "ami-065681da47fb4e433"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.nats_subnet.id
  security_groups             = [aws_security_group.nats_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "nats-server-${count.index + 1}"
  }

  user_data = <<-EOF
              #!/bin/bash
              curl -O https://github.com/nats-io/nats-server/releases/download/v2.6.0/nats-server-v2.6.0-linux-amd64.zip
              unzip nats-server-v2.6.0-linux-amd64.zip
              chmod +x nats-server-v2.6.0-linux-amd64/nats-server
              ./nats-server-v2.6.0-linux-amd64/nats-server -c /etc/nats/nats-server.conf
              EOF
}

resource "aws_route53_zone" "nats_com" {
  name = "nats.com"
}

resource "aws_route53_record" "nats_server_dns" {
  count   = 3
  zone_id = aws_route53_zone.nats_com.zone_id
  name    = "nats-server-${count.index + 1}.nats.com"
  type    = "A"
  ttl     = 300
  records = [aws_instance.nats_server[count.index].public_ip]
}