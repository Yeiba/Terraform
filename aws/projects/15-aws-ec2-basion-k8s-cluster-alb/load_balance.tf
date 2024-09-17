

resource "aws_lb" "k8_masters_lb" {
    name        = "k8-masters-lb"
    internal    = true
    load_balancer_type = "network"
    subnets = module.vpc.private_subnets #[for subnet in module.vpc.private_subnets : subnet.id]
    tags = {
    Terraform = "true"
    Environment = "dev"
  }
  
}

# target_type instance not working well when we bound this LB as a control-plane-endpoint. hence had to use IP target_type
#https://stackoverflow.com/questions/56768956/how-to-use-kubeadm-init-configuration-parameter-controlplaneendpoint/70799078#70799078

resource "aws_lb_target_group" "k8_masters_api" {
    name = "k8-masters-api"
    port = 6443
    protocol = "TCP"
    vpc_id = module.vpc.vpc_id
    target_type = "ip"

    health_check {
      port      = 6443
      protocol  = "TCP"
      interval  = 30
      healthy_threshold = 2
      unhealthy_threshold = 2
    }
}

resource "aws_lb_listener" "k8_masters_lb_listener" {
    load_balancer_arn = aws_lb.k8_masters_lb.arn
    port = 6443
    protocol = "TCP"

    default_action {
        target_group_arn = aws_lb_target_group.k8_masters_api.id
        type = "forward"
    }
}

resource "aws_lb_target_group_attachment" "k8_masters_attachment" {
    count = length(aws_instance.masters.*.id)
    target_group_arn = aws_lb_target_group.k8_masters_api.arn
    target_id = aws_instance.masters.*.private_ip[count.index]
}

resource "aws_lb" "k8_workers_lb" {
  name               = "k8-workers-lb"
  internal           = false
  load_balancer_type = "network"
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.lb_sg.id]

  enable_deletion_protection = false

}

resource "aws_lb_target_group" "k8_workers_tg" {
  name        = "k8-workers-tg"
  port        = 80                     # Use HTTP port for ALB.
  protocol    = "TCP"                 # ALB should use HTTP protocol for the target group.
  vpc_id      = module.vpc.vpc_id
  target_type = "ip" # instance

  health_check {
    path                = "/healthz" 
    interval            = 30
    healthy_threshold   = 6
    unhealthy_threshold = 6
  }
}


resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.k8_workers_lb.arn
  port              = 80
  protocol          = "TCP"
  default_action {
    target_group_arn = aws_lb_target_group.k8_workers_tg.arn
    type             = "forward"
  }
  # default_action {
  #   type = "redirect"

  #   redirect {
  #     protocol = "HTTPS"
  #     port     = "443"
  #     status_code = "HTTP_301"
  #   }
  # }
}

# resource "aws_lb_listener" "https_listener" {
#   load_balancer_arn = aws_lb.k8_workers_alb.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = var.certificate_arn  # Set the ARN of your SSL/TLS certificate

#   default_action {
#     target_group_arn = aws_lb_target_group.k8_workers_tg.arn
#     type             = "forward"
#   }
# }

#============================================================================

resource "null_resource" "configure_alb" {
  depends_on = [
    aws_lb.k8_workers_lb,
    aws_lb_target_group.k8_workers_tg,
    null_resource.run_ansible,
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

resource "null_resource" "get_pod_ip" {
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
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl get svc -n ingress-nginx | head -n 2 | grep ingress-nginx-controller | awk '{print $4}'",
      "ssh -o StrictHostKeyChecking=no ${var.ssh_user}@$ip kubectl get svc -n ingress-nginx | head -n 2 | grep ingress-nginx-controller | awk '{print $4}' > /tmp/pod_ip",
      "cat /tmp/pod_ip",
    ] 
  }

  provisioner "local-exec" {
    command = <<EOT
      sleep 30
      scp -i ${path.module}/k8_ssh_key.pem -o StrictHostKeyChecking=no ${var.ssh_user}@${aws_instance.bastion.public_ip}:/tmp/pod_ip ${path.module}/pod_ip
    EOT
  }
}

data "local_file" "pod_ip" {
  depends_on = [null_resource.get_pod_ip]
  filename = "${path.module}/pod_ip"
}

resource "aws_lb_target_group_attachment" "workers_tg_attachment" {
  depends_on          = [null_resource.get_pod_ip]
  count               = length(aws_instance.masters.*.id)
  target_group_arn    = aws_lb_target_group.k8_workers_tg.arn
  target_id           = aws_instance.workers.*.private_ip[count.index]
  port                = 80
}
# resource "aws_lb_target_group_attachment" "workers_tg_attachment" {
#   depends_on          = [null_resource.get_pod_ip]
#   target_group_arn    = aws_lb_target_group.k8_workers_tg.arn
#   target_id           = data.local_file.pod_ip.content
#   port                = 80
# }