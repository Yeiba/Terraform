# Network Load Balancer
resource "aws_lb" "k8_workers_nlb" {
  depends_on = [null_resource.get_pod_ip_ingress_port]
  name               = "k8-workers-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = module.vpc.private_subnets

  enable_cross_zone_load_balancing = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# NLB Target Group
resource "aws_lb_target_group" "k8_workers_nlb_tg" {
  depends_on = [aws_lb.k8_workers_nlb]
  name        = "k8-workers-nlb-tg"
  port        = local.nlb_http_port  # Default NodePort for Nginx Ingress HTTP
  protocol    = "TCP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip" # instance or ip

  health_check {
    protocol            = "TCP"
    port                = "traffic-port"
    healthy_threshold   = 2  # Increase to 5 successful checks
    unhealthy_threshold = 3  # Reduce from 10 to 5 for quicker detection
    interval            = 30 # Check every 30 seconds instead of 10
  }
}

# NLB Listener for HTTP
resource "aws_lb_listener" "nlb_listener_http" {
  depends_on = [aws_lb_target_group.k8_workers_nlb_tg]
  load_balancer_arn = aws_lb.k8_workers_nlb.arn
  port              = local.nlb_http_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8_workers_nlb_tg.arn
  }
}

# NLB Listener for HTTPS
resource "aws_lb_listener" "nlb_listener_https" {
  depends_on = [aws_lb_target_group.k8_workers_nlb_tg]
  load_balancer_arn = aws_lb.k8_workers_nlb.arn
  port              = local.nlb_https_port  # Default NodePort for Nginx Ingress HTTPS
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8_workers_nlb_tg.arn
  }
}


resource "aws_lb_target_group_attachment" "k8_workers_nlb_attachment" {
  depends_on = [aws_lb_target_group.k8_workers_nlb_tg]
  target_group_arn = aws_lb_target_group.k8_workers_nlb_tg.arn
  target_id           = local.nlb_pod_ip
  port                = local.nlb_http_port
}

#===========================Application Load Balancer (ALB)=====================================


# Application Load Balancer (ALB)
resource "aws_lb" "k8_workers_alb" {

  name               = "k8-workers-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets

  enable_cross_zone_load_balancing = true

  security_groups = [aws_security_group.alb_sg.id]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# ALB Target Group
resource "aws_lb_target_group" "k8_workers_alb_tg" {
  depends_on = [aws_lb.k8_workers_alb]
  name        = "k8-workers-alb-tg"
  port        = local.alb_http_port
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip" # instance or ip

  health_check {
    path                = "/healthz"  # Default health check path for Nginx Ingress
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2 # Increase to 5 successful checks
    unhealthy_threshold = 5  # Reduce from 10 to 5 for quicker detection
    timeout             = 10 # Increase timeout to 10 seconds for slow responses
    interval            = 30 # Check every 30 seconds instead of 10
    matcher             = "200-399"
  }
}

# ALB HTTP Listener
resource "aws_lb_listener" "http" {
  depends_on = [aws_lb_target_group.k8_workers_alb_tg]
  load_balancer_arn = aws_lb.k8_workers_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8_workers_alb_tg.arn
  }

  # default_action {
  #   type = "redirect"
  #   redirect {
  #     port        = "443"
  #     protocol    = "HTTPS"
  #     status_code = "HTTP_301"
  #   }
  # }
}

# resource "aws_acm_certificate" "acm_cert" {
#   domain_name       = "yourdomain.com"  # Replace with your custom domain
#   validation_method = "DNS"

#   tags = {
#     Name = "ALB ACM Certificate"
#   }
# }

# # ALB HTTPS Listener
# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.k8_workers_alb.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = aws_acm_certificate.acm_cert.arn # You need to provide this variable

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.k8_workers_alb_tg.arn
#   }
# }



resource "aws_lb_target_group_attachment" "k8_workers_alb_attachment" {
  depends_on = [aws_lb_target_group.k8_workers_alb_tg]
  target_group_arn = aws_lb_target_group.k8_workers_alb_tg.arn
  target_id           = local.alb_pod_ip
  port                = local.alb_http_port
}

#============================================================================

resource "null_resource" "configure_alb" {
  depends_on = [
    null_resource.run_ansible
  ]

  provisioner "local-exec" {
    command = "echo 'NGINX Ingress Controller installation and NLB setup complete'"
  }
}

resource "null_resource" "get_first_master_ip" {
  depends_on = [null_resource.configure_alb]

  triggers = {
    always_run = timestamp()
  }

  connection {
    type        = "ssh"
    host        = aws_instance.bastion.public_ip
    user        = var.ssh_user
    private_key = tls_private_key.ssh.private_key_pem
    insecure    = true
    agent       = false
  }
  
  provisioner "local-exec" {
    command = <<EOT
      sleep 20
      sed -n '/\[masters_first\]/,/\[masters_others\]/p' inventory | awk '{print $2}' | grep  ansible_host= | cut -d '=' -f 2 > ${path.module}/temp/master_ip
      chmod 600 ${path.module}/k8_ssh_key.pem
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${path.module}/temp/master_ip ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/master_ip 
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${path.module}/k8s-deployment/ingress-nginx-nlb-4-10.0.yaml ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/ingress-nginx-nlb-4-10.0.yaml
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${path.module}/k8s-deployment/ingress-nginx-alb-4-10.0.yaml ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/ingress-nginx-alb-4-10.0.yaml
    EOT
  }
}

resource "null_resource" "get_pod_ip_ingress_port" {
  depends_on = [null_resource.get_first_master_ip]

  triggers = {
    always_run = timestamp()
  }

  connection {
    type        = "ssh"
    host        = aws_instance.bastion.public_ip
    user        = var.ssh_user
    private_key = tls_private_key.ssh.private_key_pem
    insecure    = true
    agent       = false
  }


  provisioner "remote-exec" {
    inline = [
      "export ip=$(cat /tmp/master_ip)",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl create ns kube-system",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip sudo helm repo add flannel https://flannel-io.github.io/flannel/",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip sudo helm install flannel flannel/flannel --namespace kube-system --set podCidr=192.168.0.0/16",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip sleep 20",
      # "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl create ns ingress-nginx-nlb",
      # "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl create ns ingress-nginx-alb",
      "scp -o StrictHostKeyChecking=no /tmp/ingress-nginx-nlb-4-10.0.yaml ${var.ssh_user}@$ip:/tmp/ingress-nginx-nlb-4-10.0.yaml",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl apply -f /tmp/ingress-nginx-nlb-4-10.0.yaml",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip sleep 20",
      "scp -o StrictHostKeyChecking=no /tmp/ingress-nginx-alb-4-10.0.yaml ${var.ssh_user}@$ip:/tmp/ingress-nginx-alb-4-10.0.yaml",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl apply -f /tmp/ingress-nginx-alb-4-10.0.yaml",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip sleep 120",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl get svc -n ingress-nginx-nlb | head -n 2 | grep ingress-nginx-controller | awk '{print $5}' | cut -d ',' -f 1 | cut -d '/' -f 1 | cut -d ':' -f 2 > /tmp/nlb_http_port",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl get svc -n ingress-nginx-nlb | head -n 2 | grep ingress-nginx-controller | awk '{print $5}' | cut -d ',' -f 2 | cut -d '/' -f 1 | cut -d ':' -f 2 > /tmp/nlb_https_port",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl get svc -n ingress-nginx-alb | head -n 2 | grep ingress-nginx-controller | awk '{print $5}' | cut -d ',' -f 1 | cut -d '/' -f 1 | cut -d ':' -f 2 > /tmp/alb_http_port",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl get svc -n ingress-nginx-alb | head -n 2 | grep ingress-nginx-controller | awk '{print $5}' | cut -d ',' -f 2 | cut -d '/' -f 1 | cut -d ':' -f 2 > /tmp/alb_https_port",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip sleep 120",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl get pods -n ingress-nginx-nlb -o wide | head -n 4 | grep ingress-nginx-controller | awk '{print $7}' > /tmp/nlb_pod_ip",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip sleep 20",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl get pods -n ingress-nginx-alb -o wide | head -n 4 | grep ingress-nginx-controller | awk '{print $7}' > /tmp/alb_pod_ip",
      "cat /tmp/nlb_pod_ip",
      "cat /tmp/alb_pod_ip",
      "export nlb_pod_ip=$(cat /tmp/nlb_pod_ip)",
      "export alb_pod_ip=$(cat /tmp/alb_pod_ip)",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl get nodes -o wide | grep -w $nlb_pod_ip | awk '{print $6}' > /tmp/nlb_pod_ip",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip sleep 20",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl get nodes -o wide | grep -w $alb_pod_ip | awk '{print $6}' > /tmp/alb_pod_ip",
      "cat /tmp/nlb_http_port",
      "cat /tmp/nlb_https_port",
      "cat /tmp/nlb_pod_ip",
      "cat /tmp/alb_http_port",
      "cat /tmp/alb_https_port",
      "cat /tmp/alb_pod_ip",
    ] 
  }

  provisioner "local-exec" {
    command = <<EOT
      sleep 20
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/nlb_http_port ${path.module}/temp/nlb_http_port
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/nlb_https_port ${path.module}/temp/nlb_https_port
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/nlb_pod_ip ${path.module}/temp/nlb_pod_ip
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/alb_http_port ${path.module}/temp/alb_http_port
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/alb_https_port ${path.module}/temp/alb_https_port
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/alb_pod_ip ${path.module}/temp/alb_pod_ip
    EOT
  }
}

data "local_file" "nlb_pod_ip" {
  depends_on = [null_resource.get_pod_ip_ingress_port]
  filename = "${path.module}/temp/nlb_pod_ip"
}
data "local_file" "nlb_http_port" {
  depends_on = [null_resource.get_pod_ip_ingress_port]
  filename = "${path.module}/temp/nlb_http_port"
}
data "local_file" "nlb_https_port" {
  depends_on = [null_resource.get_pod_ip_ingress_port]
  filename = "${path.module}/temp/nlb_https_port"
}

#================================================================

data "local_file" "alb_pod_ip" {
  depends_on = [null_resource.get_pod_ip_ingress_port]
  filename = "${path.module}/temp/alb_pod_ip"
}
data "local_file" "alb_http_port" {
  depends_on = [null_resource.get_pod_ip_ingress_port]
  filename = "${path.module}/temp/alb_http_port"
}
data "local_file" "alb_https_port" {
  depends_on = [null_resource.get_pod_ip_ingress_port]
  filename = "${path.module}/temp/alb_https_port"
}

locals {
  nlb_http_port  = tonumber(trimspace(data.local_file.nlb_http_port.content))
  nlb_https_port = tonumber(trimspace(data.local_file.nlb_https_port.content))
  nlb_pod_ip = trimspace(data.local_file.nlb_pod_ip.content)

  alb_http_port  = tonumber(trimspace(data.local_file.alb_http_port.content))
  alb_https_port = tonumber(trimspace(data.local_file.alb_https_port.content))
  alb_pod_ip = trimspace(data.local_file.alb_pod_ip.content)
}
