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
  port        = data.local_file.http_port.content  # Default NodePort for Nginx Ingress HTTP
  protocol    = "TCP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance" # instance or ip

  health_check {
    protocol            = "TCP"
    port                = data.local_file.http_port.content
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
  }
}

# NLB Listener for HTTP
resource "aws_lb_listener" "nlb_listener_http" {
  depends_on = [aws_lb_target_group.k8_workers_nlb_tg]
  load_balancer_arn = aws_lb.k8_workers_nlb.arn
  port              = data.local_file.http_port.content
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
  port              = data.local_file.https_port.content  # Default NodePort for Nginx Ingress HTTPS
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8_workers_nlb_tg.arn
  }
}

# Attach worker nodes to NLB target group
resource "aws_lb_target_group_attachment" "k8_workers_nlb_attachment" {
  depends_on = [aws_lb_target_group.k8_workers_nlb_tg]
  count            = length(aws_instance.workers.*.id)
  target_group_arn = aws_lb_target_group.k8_workers_nlb_tg.arn
  target_id        = aws_instance.workers.*.id[count.index]
  port             = data.local_file.http_port.content
}


# Update the existing k8_workers security group to allow traffic from NLB
resource "aws_security_group_rule" "workers_ingress_from_nlb_http" {
  depends_on = [aws_lb_target_group.k8_workers_alb_tg]
  type              = "ingress"
  from_port         = data.local_file.http_port.content
  to_port           = data.local_file.http_port.content
  protocol          = "tcp"
  cidr_blocks       = module.vpc.private_subnets_cidr_blocks
  security_group_id = aws_security_group.k8_workers.id
}

resource "aws_security_group_rule" "workers_ingress_from_nlb_https" {
  depends_on = [aws_lb_target_group.k8_workers_alb_tg]
  type              = "ingress"
  from_port         = data.local_file.https_port.content
  to_port           = data.local_file.https_port.content
  protocol          = "tcp"
  cidr_blocks       = module.vpc.private_subnets_cidr_blocks
  security_group_id = aws_security_group.k8_workers.id
}


#===========================Application Load Balancer (ALB)=====================================

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP and HTTPS traffic to ALB"
  vpc_id      = module.vpc.vpc_id

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


# Application Load Balancer (ALB)
resource "aws_lb" "k8_workers_alb" {
  depends_on = [aws_lb_target_group_attachment.k8_workers_nlb_attachment]
  name               = "k8-workers-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets

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
  port        = data.local_file.http_port.content
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path                = "/healthz"  # Default health check path for Nginx Ingress
    port                = data.local_file.http_port.content
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 10
    matcher             = "200"
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

#   default_action {
#     type = "redirect"
#     redirect {
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }
}

# ALB HTTPS Listener
# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.k8_workers_alb.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = var.acm_certificate_arn  # You need to provide this variable

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.k8_workers_alb_tg.arn
#   }
# }


resource "aws_lb_target_group_attachment" "k8_workers_alb_attachment" {
  depends_on = [aws_lb_target_group.k8_workers_alb_tg]
  count            = length(aws_instance.workers.*.id)  # Use the IP addresses of your worker nodes
  target_group_arn = aws_lb_target_group.k8_workers_alb_tg.arn
  target_id        = aws_instance.workers.*.private_ip[count.index]  # Attach the worker node private IPs
  port             = data.local_file.http_port.content
}

# Fetch AWS IP ranges for the ALB in your region
data "aws_ip_ranges" "alb_ips" {
  services = ["ALB"]
  regions  = var.availability_zones  # Replace with your region if different
}

# Allow HTTP traffic from ALB to worker nodes
resource "aws_security_group_rule" "workers_ingress_from_alb_http" {
  depends_on = [aws_lb_target_group.k8_workers_alb_tg]
  type              = "ingress"
  from_port         = data.local_file.http_port.content  # Ensure this is a valid port number for HTTP
  to_port           = data.local_file.http_port.content
  protocol          = "tcp"
  cidr_blocks       = data.aws_ip_ranges.alb_ips.cidr_blocks # Use the ALB's DNS or its CIDR (can change depending on your ALB setup)
  security_group_id = aws_security_group.k8_workers.id  # Target the worker nodes' security group
}

# Allow HTTPS traffic from ALB to worker nodes
resource "aws_security_group_rule" "workers_ingress_from_alb_https" {
  depends_on = [aws_lb_target_group.k8_workers_alb_tg]
  type              = "ingress"
  from_port         = data.local_file.https_port.content # Ensure this is a valid port number for HTTPS
  to_port           = data.local_file.https_port.content
  protocol          = "tcp"
  cidr_blocks       = data.aws_ip_ranges.alb_ips.cidr_blocks  # Use the ALB's DNS or its CIDR (can change depending on your ALB setup)
  security_group_id = aws_security_group.k8_workers.id  # Target the worker nodes' security group
}


# Output the ALB DNS name
output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.k8_workers_alb.dns_name
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
      sleep 30
      sed -n '/\[masters_first\]/,/\[masters_others\]/p' inventory | awk '{print $2}' | grep  ansible_host= | cut -d '=' -f 2 > master_ip
      chmod 600 ${path.module}/k8_ssh_key.pem
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${path.module}/master_ip ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/master_ip 
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
      # "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip sudo helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx",
      # "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip sudo helm template ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --version 4.10.0 --namespace ingress-nginx > /tmp/ingress-nginx-1-10.0.yaml ",
      # "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip sudo kubectl apply -f /tmp/ingress-nginx-1-10.0.yaml",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl create ns ingress-nginx ",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip sleep 120",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl get svc -n ingress-nginx | head -n 2 | grep ingress-nginx-controller | awk '{print $5}' | cut -d ',' -f 1 | cut -d '/' -f 1 | cut -d ':' -f 2 > /tmp/http_port",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl get svc -n ingress-nginx | head -n 2 | grep ingress-nginx-controller | awk '{print $5}' | cut -d ',' -f 2 | cut -d '/' -f 1 | cut -d ':' -f 2 > /tmp/https_port",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip sleep 120",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl get svc -n ingress-nginx | head -n 2 | grep ingress-nginx-controller | awk '{print $4}' > /tmp/pod_ip",
      "cat /tmp/http_port",
      "cat /tmp/https_port",
      "cat /tmp/pod_ip",
    ] 
  }

  provisioner "local-exec" {
    command = <<EOT
      sleep 30
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/http_port ${path.module}/http_port
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/https_port ${path.module}/https_port
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/pod_ip ${path.module}/pod_ip
    EOT
  }
}

data "local_file" "pod_ip" {
  depends_on = [null_resource.get_pod_ip_ingress_port]
  filename = "${path.module}/pod_ip"
}
data "local_file" "http_port" {
  depends_on = [null_resource.get_pod_ip_ingress_port]
  filename = "${path.module}/http_port"
}
data "local_file" "https_port" {
  depends_on = [null_resource.get_pod_ip_ingress_port]
  filename = "${path.module}/https_port"
}

# resource "aws_lb_target_group_attachment" "workers_tg_attachment" {
#   depends_on          = [null_resource.get_pod_ip]
#   target_group_arn    = aws_lb_target_group.k8_workers_tg.arn
#   target_id           = data.local_file.pod_ip.content
#   port                = 80
# }