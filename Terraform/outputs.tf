output "address" {
  value = aws_lb.web.dns_name
}

output "aws_instance_dns" {
  value = aws_instance.web.*.public_dns
}



