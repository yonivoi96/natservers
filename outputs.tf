output "private_ips" {
  value = aws_instance.nats_server[*].private_ip
}

output "public_ips" {
  value = aws_instance.nats_server[*].public_ip
}