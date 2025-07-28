# Launch Template for Web Servers
resource "aws_launch_template" "web" {
  name_prefix   = "${var.name_prefix}-web-"
  description   = "Launch template for web servers"
  image_id      = var.ami_id
  instance_type = var.web_instance_type
  
  vpc_security_group_ids = var.web_security_group_ids
  
  user_data = base64encode(templatefile("${path.module}/user_data/web_server.sh", {
    project_name = var.name_prefix
    environment  = split("-", var.name_prefix)[1]
    db_endpoint  = var.db_endpoint
  }))
  
  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.name_prefix}-web-server"
      Tier = "Web"
    })
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Launch Template for App Servers
resource "aws_launch_template" "app" {
  name_prefix   = "${var.name_prefix}-app-"
  description   = "Launch template for application servers"
  image_id      = var.ami_id
  instance_type = var.app_instance_type
  
  vpc_security_group_ids = var.app_security_group_ids
  
  user_data = base64encode(templatefile("${path.module}/user_data/app_server.sh", {
    project_name = var.name_prefix
    environment  = split("-", var.name_prefix)[1]
    db_endpoint  = var.db_endpoint
  }))
  
  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.name_prefix}-app-server"
      Tier = "Application"
    })
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for Web Servers
resource "aws_autoscaling_group" "web" {
  name                = "${var.name_prefix}-web-asg"
  vpc_zone_identifier = var.web_subnet_ids
  min_size            = var.web_min_size
  max_size            = var.web_max_size
  desired_capacity    = var.web_min_size
  
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  
  # Health check configuration
  health_check_type         = "ELB"
  health_check_grace_period = 300
  
  # Instance refresh configuration
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
  
  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-web-asg"
    propagate_at_launch = true
  }
  
  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for App Servers
resource "aws_autoscaling_group" "app" {
  name                = "${var.name_prefix}-app-asg"
  vpc_zone_identifier = var.app_subnet_ids
  min_size            = var.app_min_size
  max_size            = var.app_max_size
  desired_capacity    = var.app_min_size
  
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  
  # Health check configuration
  health_check_type         = "EC2"
  health_check_grace_period = 300
  
  # Instance refresh configuration
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
  
  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-app-asg"
    propagate_at_launch = true
  }
  
  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Policies for Web Tier
resource "aws_autoscaling_policy" "web_scale_up" {
  name                   = "${var.name_prefix}-web-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

resource "aws_autoscaling_policy" "web_scale_down" {
  name                   = "${var.name_prefix}-web-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}