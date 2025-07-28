locals {
  # Environment-specific configurations
  environment_config = {
    dev = {
      web_instance_type    = "t3.micro"
      app_instance_type    = "t3.small"
      db_instance_class    = "db.t3.micro"
      web_min_size        = 1
      web_max_size        = 2
      app_min_size        = 1
      app_max_size        = 2
      enable_monitoring   = false
      backup_retention    = 7
    }
    staging = {
      web_instance_type    = "t3.small"
      app_instance_type    = "t3.medium"
      db_instance_class    = "db.t3.small"
      web_min_size        = 1
      web_max_size        = 3
      app_min_size        = 1
      app_max_size        = 3
      enable_monitoring   = true
      backup_retention    = 14
    }
    prod = {
      web_instance_type    = "t3.medium"
      app_instance_type    = "t3.large"
      db_instance_class    = "db.r5.large"
      web_min_size        = 2
      web_max_size        = 10
      app_min_size        = 2
      app_max_size        = 8
      enable_monitoring   = true
      backup_retention    = 30
    }
  }
  
  # Current environment configuration
  current_config = local.environment_config[var.environment]
  
  # Common naming convention
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Common tags applied to all resources
  common_tags = merge(var.common_tags, {
    Environment   = var.environment
    Project       = var.project_name
    ManagedBy     = "terraform"
    CreatedDate   = formatdate("YYYY-MM-DD", timestamp())
  })
  
  # Availability zones (first 2 in region)
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
}