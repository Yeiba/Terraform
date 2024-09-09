output "nginx_ingress_lb_dns" {
  value = helm_release.nginx_ingress.status.load_balancer.ingress[0].hostname
}