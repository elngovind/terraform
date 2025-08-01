# Network Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "IDs of the private application subnets"
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "IDs of the private database subnets"
  value       = aws_subnet.private_db[*].id
}

# Load Balancer Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "app_alb_dns_name" {
  description = "DNS name of the internal Application Load Balancer"
  value       = aws_lb.app_internal.dns_name
}

# Auto Scaling Group Outputs
output "web_asg_name" {
  description = "Name of the web tier Auto Scaling Group"
  value       = aws_autoscaling_group.web.name
}

output "web_asg_arn" {
  description = "ARN of the web tier Auto Scaling Group"
  value       = aws_autoscaling_group.web.arn
}

output "app_asg_name" {
  description = "Name of the app tier Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "app_asg_arn" {
  description = "ARN of the app tier Auto Scaling Group"
  value       = aws_autoscaling_group.app.arn
}

# Database Outputs
output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "database_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "database_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.main.arn
}

# Security Group Outputs
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "web_security_group_id" {
  description = "ID of the web tier security group"
  value       = aws_security_group.web.id
}

output "app_security_group_id" {
  description = "ID of the app tier security group"
  value       = aws_security_group.app.id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}

# Bastion Host Outputs
output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = var.create_bastion ? aws_instance.bastion[0].public_ip : null
}

output "bastion_instance_id" {
  description = "Instance ID of the bastion host"
  value       = var.create_bastion ? aws_instance.bastion[0].id : null
}

# Application URL
output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_lb.main.dns_name}"
}

# Infrastructure Summary
output "infrastructure_summary" {
  description = "Summary of the deployed infrastructure"
  value = {
    project_name          = var.project_name
    environment          = var.environment
    vpc_id               = aws_vpc.main.id
    availability_zones   = var.availability_zone_count
    public_subnets       = length(aws_subnet.public)
    private_app_subnets  = length(aws_subnet.private_app)
    private_db_subnets   = length(aws_subnet.private_db)
    nat_gateways         = var.enable_nat_gateway ? length(aws_nat_gateway.main) : 0
    web_instances        = "${var.web_asg_min_size}-${var.web_asg_max_size}"
    app_instances        = "${var.app_asg_min_size}-${var.app_asg_max_size}"
    database_multi_az    = var.db_multi_az
    bastion_created      = var.create_bastion
    application_url      = "http://${aws_lb.main.dns_name}"
  }
}

# Cost Estimation (Approximate)
output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown (USD)"
  value = {
    note = "Approximate costs - actual costs may vary"
    alb = "$16-20"
    nat_gateways = var.enable_nat_gateway ? "$${var.availability_zone_count * 45}" : "$0"
    web_instances = "$${var.web_asg_desired_capacity * 8.5} (t3.micro)"
    app_instances = "$${var.app_asg_desired_capacity * 17} (t3.small)"
    database = var.db_multi_az ? "$26 (Multi-AZ)" : "$13 (Single-AZ)"
    bastion = var.create_bastion ? "$8.5" : "$0"
    total_estimate = "~$${16 + (var.enable_nat_gateway ? var.availability_zone_count * 45 : 0) + (var.web_asg_desired_capacity * 8.5) + (var.app_asg_desired_capacity * 17) + (var.db_multi_az ? 26 : 13) + (var.create_bastion ? 8.5 : 0)}"
  }
}