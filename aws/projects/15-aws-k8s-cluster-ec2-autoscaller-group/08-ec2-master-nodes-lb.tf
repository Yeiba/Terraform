resource "aws_instance" "k8s_master" {
  count             = 3
  ami               = var.ami_id
  instance_type     = var.master_instance_type
  subnet_id         = aws_subnet.public_zone1.id
  security_groups   = [aws_security_group.k8s_master_sg.id]
  key_name           = var.key_name

#   user_data = <<-EOF
#     #!/bin/bash
    
#   EOF
  tags = {
    Name = "${var.env}-k8s-master-${count.index + 1}"
  }
}

resource "aws_lb" "k8s_master_nlb" {
  name               = "${var.env}-k8s-master-nlb"
  internal           = false
  load_balancer_type = "network"
  security_groups    = [aws_security_group.k8s_master_sg.id]
  subnets            = [aws_subnet.public_zone1.id, aws_subnet.public_zone2.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.env}-k8s-master-nlb"
  }
}

resource "aws_lb_target_group" "k8s_master_tg" {
  name     = "${var.env}-k8s-master-tg"
  port     = 6443
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  health_check {
    port                = 6443
    protocol            = "TCP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.env}-k8s-master-tg"
  }
}

resource "aws_lb_listener" "k8s_master_listener" {
  load_balancer_arn = aws_lb.k8s_master_nlb.arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_master_tg.arn
  }
}
