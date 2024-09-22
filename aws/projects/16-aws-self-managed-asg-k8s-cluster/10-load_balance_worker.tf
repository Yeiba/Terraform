# # Data source to fetch information about instances in the ASG
data "aws_instances" "workers" {
  instance_tags = {
    "aws:autoscaling:groupName" = aws_autoscaling_group.worker_asg.name
  }
  
  instance_state_names = ["running"]
  
  depends_on = [aws_autoscaling_group.worker_asg]
}

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

# resource "null_resource" "k8_workers_nlb_attachment" {
#   depends_on = [
#     aws_autoscaling_group.worker_asg,
#     aws_lb_target_group.k8_workers_nlb_tg  # Ensure this is the correct target group
#   ]

#   provisioner "local-exec" {
#     command = <<EOT
#       aws autoscaling attach-load-balancer-target-groups --auto-scaling-group-name ${aws_autoscaling_group.worker_asg.name} --target-group-arn ${aws_lb_target_group.k8_workers_nlb_tg.arn}
#     EOT
#   }
# }


resource "aws_lb_target_group_attachment" "k8_workers_nlb_attachment" {
  # for_each = toset(data.aws_instances.workers.private_ips)
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
  # for_each = toset(data.aws_instances.workers.private_ips)
  depends_on = [aws_lb_target_group.k8_workers_alb_tg]
  target_group_arn = aws_lb_target_group.k8_workers_alb_tg.arn
  target_id           = local.alb_pod_ip
  port                = local.alb_http_port
}

#============================================================================

