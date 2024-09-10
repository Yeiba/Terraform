output "external_nginx_lb_dns" {
  description = "The DNS name of the external NGINX load balancer"
  value       = aws_lb.k8s_alb.dns_name
}
