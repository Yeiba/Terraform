output "bastion_host_public_ip" {
  value = aws_instance.bastion.public_ip
}

# Output the ALB DNS name
output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.k8_workers_alb.dns_name
}

# # Output the DNS validation details
# output "acm_dns_validation" {
#   value = aws_acm_certificate.acm_cert.domain_validation_options
# }