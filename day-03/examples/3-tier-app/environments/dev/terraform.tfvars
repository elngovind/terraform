# Development Environment Configuration
project_name = "3tier-app"
environment  = "dev"
owner        = "Development Team"

# AWS Configuration
aws_region             = "us-west-2"
availability_zone_count = 2

# Network Configuration
vpc_cidr           = "10.1.0.0/16"
enable_nat_gateway = false  # Cost optimization for dev

# Web Tier Configuration (Minimal for dev)
web_instance_type        = "t3.micro"
web_asg_min_size        = 1
web_asg_max_size        = 2
web_asg_desired_capacity = 1

# Application Tier Configuration (Minimal for dev)
app_instance_type        = "t3.micro"
app_asg_min_size        = 1
app_asg_max_size        = 2
app_asg_desired_capacity = 1

# Database Configuration (Development Settings)
db_instance_class           = "db.t3.micro"
db_allocated_storage        = 20
db_max_allocated_storage    = 100
db_engine_version          = "8.0"
db_name                    = "devappdb"
db_username                = "devadmin"
db_password                = "devpassword123!"
db_backup_retention_period = 1
db_backup_window           = "03:00-04:00"
db_maintenance_window      = "sun:04:00-sun:05:00"
db_multi_az               = false

# Security Configuration
create_bastion              = false  # Not needed for dev
bastion_allowed_cidr_blocks = ["0.0.0.0/0"]

# Load Balancer Configuration
enable_deletion_protection = false