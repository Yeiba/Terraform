output "external_nginx_lbc_dns" {
  description = "The DNS name of the external NGINX load balancer controller"
  value       = aws_lb.k8s_alb.dns_name
}
