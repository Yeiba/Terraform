resource "aws_launch_configuration" "worker_lc" {
  name          = "worker-lc"
  image_id      = var.ami_id
  instance_type = var.master_instance_type
  security_groups = [aws_security_group.k8s_worker_sg.id]
  key_name      = var.key_name

#   user_data = <<-EOF
#     #!/bin/bash
    
#   EOF
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "worker_asg" {
  launch_configuration = aws_launch_configuration.worker_lc.id
  min_size             = 2
  max_size             = 5
  desired_capacity     = 3
  vpc_zone_identifier  = [aws_subnet.private_zone1.id, aws_subnet.private_zone2.id]

  tag {
    key                 = "Name"
    value               = "${var.env}-k8s-worker"
    propagate_at_launch = true
  }

  health_check_type           = "EC2"
  health_check_grace_period   = 300
  wait_for_capacity_timeout      = "0"
  force_delete                = true
}

resource "aws_lb" "k8s_worker_alb" {
  name               = "${var.env}-k8s-worker-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.k8s_worker_sg.id]
  subnets            = [aws_subnet.public_zone1.id, aws_subnet.public_zone2.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.env}-k8s-worker-alb"
  }
}

resource "aws_lb_target_group" "k8s_worker_tg" {
  name     = "${var.env}-k8s-worker-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/healthz"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.env}-k8s-worker-tg"
  }
}

resource "aws_lb_listener" "k8s_worker_listener" {
  load_balancer_arn = aws_lb.k8s_worker_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_worker_tg.arn
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.worker_asg.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.worker_asg.name
}
