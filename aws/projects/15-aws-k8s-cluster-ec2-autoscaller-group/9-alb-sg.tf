# Create an ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Allow access to ALB"
  vpc_id      = aws_vpc.main.id

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
}

# Create the Application Load Balancer
resource "aws_lb" "k8s_alb" {
  name               = "k8s-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_zone1.id, aws_subnet.public_zone2.id]  # Public subnets

  enable_deletion_protection = false

  tags = {
    Name = "k8s-alb"
  }
}

# Create a Target Group for the ALB
resource "aws_lb_target_group" "k8s_alb_target_group" {
  name     = "k8s-alb-tg"
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
    Name = "k8s-alb-target-group"
  }
}

# Create an ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.k8s_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_alb_target_group.arn
  }
}

resource "aws_lb_target_group_attachment" "k8s_alb_tg_attachment" {
  count            = length(aws_autoscaling_group.k8s_worker_asg.instances)
  target_group_arn = aws_lb_target_group.k8s_alb_target_group.arn
  target_id        = aws_autoscaling_group.k8s_worker_asg.instances[count.index].id
  port             = 80
}
