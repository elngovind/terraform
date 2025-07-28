# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids
  
  enable_deletion_protection = false
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb"
  })
}

# Target Group for Web Servers
resource "aws_lb_target_group" "web" {
  name     = "${var.name_prefix}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-web-tg"
  })
}

# Listener for HTTP traffic
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# Auto Scaling Group Attachment
resource "aws_autoscaling_attachment" "web" {
  autoscaling_group_name = var.web_asg_name
  lb_target_group_arn    = aws_lb_target_group.web.arn
}