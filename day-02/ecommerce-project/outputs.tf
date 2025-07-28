# Networking Outputs
output "vpc_info" {
  description = "VPC information"
  value = {
    vpc_id         = module.networking.vpc_id
    vpc_cidr       = module.networking.vpc_cidr_block
    public_subnets = module.networking.public_subnet_ids
    app_subnets    = module.networking.private_app_subnet_ids
    db_subnets     = module.networking.private_db_subnet_ids
  }
}

# Security Outputs
output "security_groups" {
  description = "Security group IDs"
  value = {
    alb_sg = module.security.alb_security_group_id
    web_sg = module.security.web_security_group_id
    app_sg = module.security.app_security_group_id
    db_sg  = module.security.db_security_group_id
  }
}

# Database Outputs
output "database_info" {
  description = "Database information"
  value = {
    db_instance_id = module.database.db_instance_id
    db_port        = module.database.db_instance_port
    secret_arn     = module.database.db_secret_arn
  }
  sensitive = true
}

# Compute Outputs
output "compute_info" {
  description = "Compute resources information"
  value = {
    web_asg_name = module.compute.web_asg_name
    app_asg_name = module.compute.app_asg_name
  }
}

# Load Balancer Outputs
output "load_balancer_info" {
  description = "Load balancer information"
  value = {
    dns_name = module.loadbalancer.dns_name
    zone_id  = module.loadbalancer.zone_id
    url      = "http://${module.loadbalancer.dns_name}"
  }
}

# Application URL
output "application_url" {
  description = "URL to access the application"
  value       = "http://${module.loadbalancer.dns_name}"
}

# Environment Summary
output "environment_summary" {
  description = "Summary of the deployed environment"
  value = {
    project_name = var.project_name
    environment  = var.environment
    region       = var.aws_region
    deployed_at  = timestamp()
  }
}