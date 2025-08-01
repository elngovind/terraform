# Production Environment Configuration
project_name = "3tier-app"
environment  = "prod"
owner        = "Production Team"

# AWS Configuration
aws_region             = "us-west-2"
availability_zone_count = 3

# Network Configuration
vpc_cidr           = "10.0.0.0/16"
enable_nat_gateway = true

# Web Tier Configuration (Production Scale)
web_instance_type        = "t3.small"
web_asg_min_size        = 2
web_asg_max_size        = 8
web_asg_desired_capacity = 3

# Application Tier Configuration (Production Scale)
app_instance_type        = "t3.medium"
app_asg_min_size        = 2
app_asg_max_size        = 10
app_asg_desired_capacity = 4

# Database Configuration (Production Settings)
db_instance_class           = "db.t3.small"
db_allocated_storage        = 100
db_max_allocated_storage    = 1000
db_engine_version          = "8.0"
db_name                    = "prodappdb"
db_username                = "prodadmin"
# db_password should be set via environment variable or AWS Secrets Manager
db_backup_retention_period = 30
db_backup_window           = "03:00-04:00"
db_maintenance_window      = "sun:04:00-sun:06:00"
db_multi_az               = true

# Security Configuration
create_bastion              = true
bastion_allowed_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12"]  # Internal networks only

# Load Balancer Configuration
enable_deletion_protection = true