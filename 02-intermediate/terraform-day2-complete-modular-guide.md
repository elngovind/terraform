# Terraform Day 2: Building Production-Ready Infrastructure
## Modular Architecture | Variables | Outputs | Real-World Project

---

## 🎯 Today's Mission: Build a Complete E-Commerce Platform Infrastructure

**What we're building:** A scalable, secure, and production-ready infrastructure for an e-commerce application with:
- Multi-tier architecture (Web, App, Database)
- Auto-scaling capabilities
- Load balancing
- Database with read replicas
- Monitoring and logging
- Disaster recovery setup

---

## 🏗️ Architecture Overview

```
Production E-Commerce Infrastructure:
├── 🌐 Public Tier (Load Balancers)
├── 🖥️  Web Tier (Frontend Servers)
├── ⚙️  Application Tier (Backend APIs)
├── 🗄️  Database Tier (RDS with replicas)
├── 📊 Monitoring (CloudWatch, SNS)
└── 🔒 Security (WAF, Security Groups)
```

---

## 📁 Project Structure (Modular Approach)

```bash
ecommerce-infrastructure/
├── main.tf                    # Root module orchestration
├── variables.tf               # Root variables
├── outputs.tf                 # Root outputs
├── terraform.tfvars          # Default values
├── locals.tf                 # Local computations
├── data.tf                   # Data sources
├── versions.tf               # Provider versions
├── 
├── modules/                  # Reusable modules
│   ├── networking/           # VPC, Subnets, Routes
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   │
│   ├── security/             # Security Groups, NACLs
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── compute/              # EC2, ASG, Launch Templates
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── user_data/
│   │       ├── web_server.sh
│   │       └── app_server.sh
│   │
│   ├── database/             # RDS, Parameter Groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── loadbalancer/         # ALB, Target Groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── monitoring/           # CloudWatch, SNS
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── environments/             # Environment-specific configs
    ├── dev/
    │   ├── terraform.tfvars
    │   └── backend.tf
    ├── staging/
    │   ├── terraform.tfvars
    │   └── backend.tf
    └── prod/
        ├── terraform.tfvars
        └── backend.tf
```

---

## 🚀 Step 1: Root Configuration Setup

### versions.tf - Provider Requirements
```hcl
terraform {
  required_version = ">= 1.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = local.common_tags
  }
}
```

### locals.tf - Computed Values & Logic
```hcl
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
```

### data.tf - External Data Sources
```hcl
# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get current AWS caller identity
data "aws_caller_identity" "current" {}

# Get current AWS region
data "aws_region" "current" {}
```

### variables.tf - Input Variables with Validation
```hcl
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ecommerce"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.aws_region))
    error_message = "AWS region must be a valid region identifier."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = ""
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Owner       = "DevOps Team"
    CostCenter  = "Engineering"
    Application = "E-Commerce Platform"
  }
}

# Database configuration
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "ecommerce"
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]*$", var.db_name))
    error_message = "Database name must start with a letter and contain only alphanumeric characters."
  }
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "enable_read_replica" {
  description = "Enable RDS read replica"
  type        = bool
  default     = false
}
```

---

## 🌐 Step 2: Networking Module

### modules/networking/variables.tf
```hcl
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = false
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
```

### modules/networking/main.tf
```hcl
# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.availability_zones)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-subnet-${count.index + 1}"
    Type = "Public"
    Tier = "Web"
  })
}

# Private Subnets for Application Tier
resource "aws_subnet" "private_app" {
  count = length(var.availability_zones)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-app-subnet-${count.index + 1}"
    Type = "Private"
    Tier = "Application"
  })
}

# Private Subnets for Database Tier
resource "aws_subnet" "private_db" {
  count = length(var.availability_zones)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 20)
  availability_zone = var.availability_zones[count.index]
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-db-subnet-${count.index + 1}"
    Type = "Private"
    Tier = "Database"
  })
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? length(var.availability_zones) : 0
  
  domain = "vpc"
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-eip-${count.index + 1}"
  })
  
  depends_on = [aws_internet_gateway.main]
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? length(var.availability_zones) : 0
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-gateway-${count.index + 1}"
  })
  
  depends_on = [aws_internet_gateway.main]
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-rt"
  })
}

# Route Tables for Private App Subnets
resource "aws_route_table" "private_app" {
  count = length(var.availability_zones)
  
  vpc_id = aws_vpc.main.id
  
  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[count.index].id
    }
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-app-rt-${count.index + 1}"
  })
}

# Route Tables for Private DB Subnets
resource "aws_route_table" "private_db" {
  count = length(var.availability_zones)
  
  vpc_id = aws_vpc.main.id
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-db-rt-${count.index + 1}"
  })
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_app" {
  count = length(aws_subnet.private_app)
  
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app[count.index].id
}

resource "aws_route_table_association" "private_db" {
  count = length(aws_subnet.private_db)
  
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db[count.index].id
}

# VPN Gateway (optional)
resource "aws_vpn_gateway" "main" {
  count = var.enable_vpn_gateway ? 1 : 0
  
  vpc_id = aws_vpc.main.id
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpn-gateway"
  })
}
```

### modules/networking/outputs.tf
```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
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

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}
```

---

## 🔒 Step 3: Security Module

### modules/security/variables.tf
```hcl
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
```

### modules/security/main.tf
```hcl
# Security Group for Application Load Balancer
resource "aws_security_group" "alb" {
  name_prefix = "${var.name_prefix}-alb-"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id
  
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-sg"
    Tier = "Load Balancer"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for Web Servers
resource "aws_security_group" "web" {
  name_prefix = "${var.name_prefix}-web-"
  description = "Security group for Web servers"
  vpc_id      = var.vpc_id
  
  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  ingress {
    description     = "HTTPS from ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-web-sg"
    Tier = "Web"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for Application Servers
resource "aws_security_group" "app" {
  name_prefix = "${var.name_prefix}-app-"
  description = "Security group for Application servers"
  vpc_id      = var.vpc_id
  
  ingress {
    description     = "HTTP from Web tier"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }
  
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-app-sg"
    Tier = "Application"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for Database
resource "aws_security_group" "db" {
  name_prefix = "${var.name_prefix}-db-"
  description = "Security group for Database"
  vpc_id      = var.vpc_id
  
  ingress {
    description     = "MySQL/Aurora from App tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
  
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-sg"
    Tier = "Database"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}
```

### modules/security/outputs.tf
```hcl
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "app_security_group_id" {
  description = "ID of the app security group"
  value       = aws_security_group.app.id
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.db.id
}
```

---

## 💾 Step 4: Database Module

### modules/database/variables.tf
```hcl
variable "subnet_ids" {
  description = "List of subnet IDs for DB subnet group"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "Database instance class"
  type        = string
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "enable_read_replica" {
  description = "Enable read replica"
  type        = bool
  default     = false
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
```

### modules/database/main.tf
```hcl
# Generate random password for database
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Store password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.name_prefix}-db-password"
  description             = "Database password for ${var.name_prefix}"
  recovery_window_in_days = 7
  
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = var.subnet_ids
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-subnet-group"
  })
}

# DB Parameter Group
resource "aws_db_parameter_group" "main" {
  family = "mysql8.0"
  name   = "${var.name_prefix}-db-params"
  
  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }
  
  tags = var.tags
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.name_prefix}-database"
  
  # Engine configuration
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class
  
  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result
  
  # Storage configuration
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true
  
  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.security_group_ids
  publicly_accessible    = false
  
  # Backup configuration
  backup_retention_period = var.backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  # Parameter group
  parameter_group_name = aws_db_parameter_group.main.name
  
  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn
  
  # Performance Insights
  performance_insights_enabled = true
  
  # Deletion protection
  deletion_protection = var.name_prefix == "prod" ? true : false
  skip_final_snapshot = var.name_prefix != "prod"
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-database"
  })
}

# Read Replica (conditional)
resource "aws_db_instance" "read_replica" {
  count = var.enable_read_replica ? 1 : 0
  
  identifier = "${var.name_prefix}-database-replica"
  
  # Replica configuration
  replicate_source_db = aws_db_instance.main.identifier
  instance_class      = var.db_instance_class
  
  # Network configuration
  publicly_accessible = false
  
  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn
  
  # Performance Insights
  performance_insights_enabled = true
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-database-replica"
  })
}

# IAM Role for RDS Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.name_prefix}-rds-monitoring-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
  
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
```

### modules/database/outputs.tf
```hcl
output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.main.id
}

output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "db_instance_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.main.name
}

output "db_secret_arn" {
  description = "ARN of the database secret"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "read_replica_endpoint" {
  description = "Read replica endpoint"
  value       = var.enable_read_replica ? aws_db_instance.read_replica[0].endpoint : null
  sensitive   = true
}
```

---

## 🖥️ Step 5: Compute Module

### modules/compute/variables.tf
```hcl
variable "ami_id" {
  description = "AMI ID for instances"
  type        = string
}

variable "web_instance_type" {
  description = "Instance type for web servers"
  type        = string
}

variable "app_instance_type" {
  description = "Instance type for app servers"
  type        = string
}

variable "web_subnet_ids" {
  description = "Subnet IDs for web servers"
  type        = list(string)
}

variable "app_subnet_ids" {
  description = "Subnet IDs for app servers"
  type        = list(string)
}

variable "web_security_group_ids" {
  description = "Security group IDs for web servers"
  type        = list(string)
}

variable "app_security_group_ids" {
  description = "Security group IDs for app servers"
  type        = list(string)
}

variable "web_min_size" {
  description = "Minimum size for web ASG"
  type        = number
}

variable "web_max_size" {
  description = "Maximum size for web ASG"
  type        = number
}

variable "app_min_size" {
  description = "Minimum size for app ASG"
  type        = number
}

variable "app_max_size" {
  description = "Maximum size for app ASG"
  type        = number
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "db_endpoint" {
  description = "Database endpoint"
  type        = string
  sensitive   = true
}
```

### modules/compute/user_data/web_server.sh
```bash
#!/bin/bash
yum update -y
yum install -y httpd php php-mysqlnd

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create a dynamic web application
cat <<'EOF' > /var/www/html/index.php
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>E-Commerce Platform - ${project_name}</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Arial', sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            padding: 40px;
            max-width: 800px;
            width: 90%;
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .header h1 {
            color: #333;
            font-size: 2.5rem;
            margin-bottom: 10px;
        }
        .header p {
            color: #666;
            font-size: 1.1rem;
        }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        .info-card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            border-left: 4px solid #667eea;
        }
        .info-card h3 {
            color: #333;
            margin-bottom: 10px;
        }
        .info-card p {
            color: #666;
            font-family: monospace;
        }
        .status {
            text-align: center;
            margin-top: 30px;
            padding: 20px;
            background: #d4edda;
            border-radius: 10px;
            border: 1px solid #c3e6cb;
        }
        .status h2 {
            color: #155724;
            margin-bottom: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🛒 E-Commerce Platform</h1>
            <p>Environment: <strong>${environment}</strong></p>
        </div>
        
        <div class="info-grid">
            <div class="info-card">
                <h3>🖥️ Server Info</h3>
                <p><strong>Instance ID:</strong><br><?php echo file_get_contents('http://169.254.169.254/latest/meta-data/instance-id'); ?></p>
            </div>
            <div class="info-card">
                <h3>🌍 Location</h3>
                <p><strong>Availability Zone:</strong><br><?php echo file_get_contents('http://169.254.169.254/latest/meta-data/placement/availability-zone'); ?></p>
            </div>
            <div class="info-card">
                <h3>⚡ Instance Type</h3>
                <p><strong>Type:</strong><br><?php echo file_get_contents('http://169.254.169.254/latest/meta-data/instance-type'); ?></p>
            </div>
            <div class="info-card">
                <h3>🕒 Timestamp</h3>
                <p><strong>Current Time:</strong><br><?php echo date('Y-m-d H:i:s T'); ?></p>
            </div>
        </div>
        
        <div class="status">
            <h2>✅ Web Tier Active</h2>
            <p>This is the web tier of our multi-tier e-commerce architecture</p>
        </div>
    </div>
</body>
</html>
EOF

# Set proper permissions
chown apache:apache /var/www/html/index.php
chmod 644 /var/www/html/index.php

# Restart Apache to load PHP
systemctl restart httpd
```

### modules/compute/main.tf
```hcl
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
```

### modules/compute/outputs.tf
```hcl
output "web_asg_name" {
  description = "Name of the web Auto Scaling Group"
  value       = aws_autoscaling_group.web.name
}

output "app_asg_name" {
  description = "Name of the app Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "web_launch_template_id" {
  description = "ID of the web launch template"
  value       = aws_launch_template.web.id
}

output "app_launch_template_id" {
  description = "ID of the app launch template"
  value       = aws_launch_template.app.id
}
```

---

## ⚖️ Step 6: Load Balancer Module

### modules/loadbalancer/main.tf
```hcl
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
```

---

## 🎯 Step 7: Main Configuration (Orchestration)

### main.tf
```hcl
# Networking Module
module "networking" {
  source = "./modules/networking"
  
  vpc_cidr           = var.vpc_cidr
  availability_zones = local.availability_zones
  enable_nat_gateway = var.enable_nat_gateway
  enable_vpn_gateway = var.enable_vpn_gateway
  name_prefix        = local.name_prefix
  tags               = local.common_tags
}

# Security Module
module "security" {
  source = "./modules/security"
  
  vpc_id      = module.networking.vpc_id
  vpc_cidr    = var.vpc_cidr
  name_prefix = local.name_prefix
  tags        = local.common_tags
}

# Database Module
module "database" {
  source = "./modules/database"
  
  subnet_ids              = module.networking.private_db_subnet_ids
  security_group_ids      = [module.security.db_security_group_id]
  db_name                 = var.db_name
  db_username             = var.db_username
  db_instance_class       = local.current_config.db_instance_class
  backup_retention_period = local.current_config.backup_retention
  enable_read_replica     = var.enable_read_replica
  name_prefix             = local.name_prefix
  tags                    = local.common_tags
}

# Compute Module
module "compute" {
  source = "./modules/compute"
  
  ami_id                 = data.aws_ami.amazon_linux.id
  web_instance_type      = local.current_config.web_instance_type
  app_instance_type      = local.current_config.app_instance_type
  web_subnet_ids         = module.networking.public_subnet_ids
  app_subnet_ids         = module.networking.private_app_subnet_ids
  web_security_group_ids = [module.security.web_security_group_id]
  app_security_group_ids = [module.security.app_security_group_id]
  web_min_size           = local.current_config.web_min_size
  web_max_size           = local.current_config.web_max_size
  app_min_size           = local.current_config.app_min_size
  app_max_size           = local.current_config.app_max_size
  name_prefix            = local.name_prefix
  tags                   = local.common_tags
  db_endpoint            = module.database.db_instance_endpoint
}

# Load Balancer Module
module "loadbalancer" {
  source = "./modules/loadbalancer"
  
  vpc_id             = module.networking.vpc_id
  subnet_ids         = module.networking.public_subnet_ids
  security_group_ids = [module.security.alb_security_group_id]
  web_asg_name       = module.compute.web_asg_name
  name_prefix        = local.name_prefix
  tags               = local.common_tags
}
```

---

## 📊 Step 8: Comprehensive Outputs

### outputs.tf
```hcl
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
```

---

## 🌍 Step 9: Environment Configurations

### environments/dev/terraform.tfvars
```hcl
# Development Environment Configuration
project_name = "ecommerce"
environment  = "dev"
aws_region   = "us-east-1"

# Network Configuration
vpc_cidr           = "10.0.0.0/16"
enable_nat_gateway = false  # Cost optimization for dev
enable_vpn_gateway = false

# Database Configuration
db_name             = "ecommerce_dev"
db_username         = "admin"
enable_read_replica = false

# Domain Configuration
domain_name = "dev.ecommerce.local"

# Tags
common_tags = {
  Owner       = "Development Team"
  CostCenter  = "Engineering"
  Application = "E-Commerce Platform"
  Environment = "Development"
  Backup      = "not-required"
}
```

### environments/prod/terraform.tfvars
```hcl
# Production Environment Configuration
project_name = "ecommerce"
environment  = "prod"
aws_region   = "us-east-1"

# Network Configuration
vpc_cidr           = "10.0.0.0/16"
enable_nat_gateway = true   # Required for production
enable_vpn_gateway = false

# Database Configuration
db_name             = "ecommerce_prod"
db_username         = "admin"
enable_read_replica = true  # Enable for production

# Domain Configuration
domain_name = "ecommerce.company.com"

# Tags
common_tags = {
  Owner       = "Operations Team"
  CostCenter  = "Production"
  Application = "E-Commerce Platform"
  Environment = "Production"
  Backup      = "required"
  Compliance  = "required"
}
```

---

## 🚀 Deployment Commands

```bash
# Initialize Terraform
terraform init

# Select workspace (optional)
terraform workspace new dev
terraform workspace select dev

# Plan with environment-specific variables
terraform plan -var-file="environments/dev/terraform.tfvars"

# Apply configuration
terraform apply -var-file="environments/dev/terraform.tfvars" -auto-approve

# Check outputs
terraform output

# Access application
terraform output application_url

# Scale up web tier (example)
terraform apply -var-file="environments/dev/terraform.tfvars" -var="web_max_size=5"

# Destroy infrastructure
terraform destroy -var-file="environments/dev/terraform.tfvars" -auto-approve
```

---

## 🎓 Key Learning Outcomes

### 1. **Modular Architecture Benefits**
- **Reusability**: Modules can be used across environments
- **Maintainability**: Changes isolated to specific modules
- **Testing**: Individual modules can be tested separately
- **Collaboration**: Teams can work on different modules

### 2. **Advanced Variable Techniques**
- **Validation**: Input validation prevents errors
- **Sensitive Variables**: Protect confidential data
- **Complex Types**: Objects and lists for structured data
- **Local Values**: Computed values and logic

### 3. **Output Organization**
- **Structured Outputs**: Organized for easy consumption
- **Sensitive Outputs**: Protect confidential information
- **Integration Ready**: Outputs designed for module chaining

### 4. **Real-World Patterns**
- **Multi-tier Architecture**: Separation of concerns
- **Auto Scaling**: Dynamic resource management
- **Security Best Practices**: Least privilege access
- **Monitoring Integration**: Built-in observability

---

## 🔧 Advanced Features Demonstrated

### 1. **Dynamic Resource Creation**
```hcl
# Conditional NAT Gateways
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? length(var.availability_zones) : 0
  # ... configuration
}
```

### 2. **Complex Data Structures**
```hcl
# Environment-specific configurations
locals {
  environment_config = {
    dev = { /* config */ }
    prod = { /* config */ }
  }
}
```

### 3. **Template Functions**
```hcl
# Dynamic user data with templates
user_data = base64encode(templatefile("${path.module}/user_data.sh", {
  project_name = var.project_name
  environment  = var.environment
}))
```

### 4. **Resource Dependencies**
```hcl
# Explicit dependencies
depends_on = [aws_internet_gateway.main]
```

---

## 🎯 Production Readiness Checklist

- ✅ **Multi-AZ Deployment**: High availability across zones
- ✅ **Auto Scaling**: Dynamic capacity management
- ✅ **Load Balancing**: Traffic distribution
- ✅ **Database Encryption**: Data protection at rest
- ✅ **Secrets Management**: Secure credential storage
- ✅ **Monitoring**: CloudWatch integration
- ✅ **Backup Strategy**: Automated database backups
- ✅ **Security Groups**: Least privilege access
- ✅ **Tagging Strategy**: Resource organization and cost tracking
- ✅ **Environment Separation**: Dev/Staging/Prod isolation

---

## 🚀 Next Steps & Advanced Topics

1. **State Management**: Remote backends with S3 + DynamoDB
2. **CI/CD Integration**: GitLab/GitHub Actions pipelines
3. **Terraform Cloud**: Collaborative infrastructure management
4. **Policy as Code**: Sentinel policies for governance
5. **Multi-Cloud**: Extending to Azure/GCP
6. **Kubernetes Integration**: EKS cluster deployment
7. **Serverless Components**: Lambda functions and API Gateway
8. **Monitoring Stack**: Prometheus, Grafana integration

---

**🎉 Congratulations!** You've built a production-ready, scalable, and maintainable infrastructure using Terraform best practices. This modular approach will serve as a foundation for complex enterprise deployments.