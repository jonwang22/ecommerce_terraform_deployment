##################################################
### APPLICATION LOAD BALANCER ###
##################################################
resource "aws_lb" "wl5alb" {
  name               = "WL5-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [var.public_subnet_1_id, var.public_subnet_2_id]

  enable_deletion_protection = false

  tags = {
    Environment = "WL5 Load Balancer Prod"
  }
}

##################################################
### ALB SECURITY GROUP ###
##################################################
resource "aws_security_group" "alb_sg" {
  name   = "wl5_alb_sg"
  vpc_id = var.wl5vpc_id

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
    Name = "wl5-alb-security-group"
  }
}

##################################################
### LISTENERS ###
##################################################
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.wl5alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

##################################################
### TARGET GROUP ###
##################################################
resource "aws_lb_target_group" "alb_tg" {
  name     = "WL5-TargetGroup"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.wl5vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
    matcher             = "200"  # Expect a 200 OK response
  }
}

##################################################
### TARGET GROUP ATTACHMENTS ###
##################################################
# Target Group Attachment for each EC2 instance
resource "aws_lb_target_group_attachment" "alb_tg_attachment-1" {
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = var.wl5frontend1  # Replace with your EC2 instance ID
  port             = 3000  # Matches the target group port
}

resource "aws_lb_target_group_attachment" "alb_tg_attachment-2" {
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = var.wl5frontend2  # Replace with your EC2 instance ID
  port             = 3000  # Matches the target group port
}