# Day 2: Modular Architecture Guide
## Building Production-Ready Infrastructure with Terraform Modules

**Duration:** 30 minutes | **Prerequisites:** Day 2 lecture completed

---

## Overview

This guide demonstrates how to build a complete e-commerce platform using Terraform's modular architecture. You'll learn to create reusable modules, manage complex configurations, and implement production-ready patterns.

---

## Architecture Overview

```
Production E-Commerce Infrastructure:
├── Public Tier (Load Balancers)
├── Web Tier (Frontend Servers)
├── Application Tier (Backend APIs)
├── Database Tier (RDS with replicas)
├── Monitoring (CloudWatch, SNS)
└── Security (WAF, Security Groups)
```

---

## Project Structure

```
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

## Module Design Principles

### 1. Single Responsibility
Each module should have one clear purpose:
- **Networking**: VPC, subnets, routing
- **Security**: Security groups, NACLs
- **Compute**: EC2, ASG, launch templates
- **Database**: RDS, parameter groups
- **Load Balancer**: ALB, target groups

### 2. Reusability
Modules should work across different environments:
```hcl
module "networking" {
  source = "./modules/networking"
  
  vpc_cidr    = var.vpc_cidr
  environment = var.environment
  tags        = local.common_tags
}
```

### 3. Composability
Modules should integrate seamlessly:
```hcl
module "compute" {
  source = "./modules/compute"
  
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids
  sg_ids     = [module.security.web_sg_id]
}
```

---

## Key Configuration Files

### Root Configuration (main.tf)
```hcl
# Networking Module
module "networking" {
  source = "./modules/networking"
  
  vpc_cidr           = var.vpc_cidr
  availability_zones = local.availability_zones
  enable_nat_gateway = var.enable_nat_gateway
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
  
  subnet_ids         = module.networking.private_db_subnet_ids
  security_group_ids = [module.security.db_security_group_id]
  db_instance_class  = local.current_config.db_instance_class
  name_prefix        = local.name_prefix
  tags               = local.common_tags
}
```

### Environment-Specific Logic (locals.tf)
```hcl
locals {
  # Environment-specific configurations
  environment_config = {
    dev = {
      web_instance_type = "t3.micro"
      db_instance_class = "db.t3.micro"
      web_min_size     = 1
      web_max_size     = 2
      enable_monitoring = false
    }
    prod = {
      web_instance_type = "t3.medium"
      db_instance_class = "db.r5.large"
      web_min_size     = 2
      web_max_size     = 10
      enable_monitoring = true
    }
  }
  
  current_config = local.environment_config[var.environment]
  name_prefix    = "${var.project_name}-${var.environment}"
  
  common_tags = merge(var.common_tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  })
}
```

---

## Advanced Module Patterns

### 1. Conditional Resources
```hcl
# Create NAT Gateway only if enabled
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? length(var.availability_zones) : 0
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
}
```

### 2. Dynamic Blocks
```hcl
# Dynamic security group rules
dynamic "ingress" {
  for_each = var.ingress_rules
  content {
    from_port   = ingress.value.from_port
    to_port     = ingress.value.to_port
    protocol    = ingress.value.protocol
    cidr_blocks = ingress.value.cidr_blocks
  }
}
```

### 3. Template Files
```hcl
# User data with templates
user_data = base64encode(templatefile("${path.module}/user_data.sh", {
  project_name = var.project_name
  environment  = var.environment
  db_endpoint  = var.db_endpoint
}))
```

---

## Environment Management

### Development Environment (dev.tfvars)
```hcl
project_name = "ecommerce"
environment  = "dev"
aws_region   = "us-east-1"

# Cost optimization for dev
enable_nat_gateway  = false
enable_read_replica = false

# Minimal resources
vpc_cidr = "10.0.0.0/16"

common_tags = {
  Owner       = "Development Team"
  Environment = "Development"
  Backup      = "not-required"
}
```

### Production Environment (prod.tfvars)
```hcl
project_name = "ecommerce"
environment  = "prod"
aws_region   = "us-east-1"

# Production requirements
enable_nat_gateway  = true
enable_read_replica = true

# Production network
vpc_cidr = "10.0.0.0/16"

common_tags = {
  Owner       = "Operations Team"
  Environment = "Production"
  Backup      = "required"
  Compliance  = "required"
}
```

---

## Best Practices Demonstrated

### 1. Variable Validation
```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

### 2. Resource Naming
```hcl
# Consistent naming convention
resource "aws_vpc" "main" {
  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}
```

### 3. Output Organization
```hcl
# Structured outputs for easy consumption
output "vpc_info" {
  value = {
    vpc_id         = module.networking.vpc_id
    public_subnets = module.networking.public_subnet_ids
    private_subnets = module.networking.private_subnet_ids
  }
}
```

### 4. Security Implementation
```hcl
# Least privilege security groups
resource "aws_security_group" "web" {
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
}
```

---

## Deployment Commands

```bash
# Initialize Terraform
terraform init

# Plan with environment-specific variables
terraform plan -var-file="environments/dev/terraform.tfvars"

# Apply configuration
terraform apply -var-file="environments/dev/terraform.tfvars"

# Check outputs
terraform output

# Scale resources (example)
terraform apply -var-file="environments/dev/terraform.tfvars" -var="web_max_size=5"

# Destroy infrastructure
terraform destroy -var-file="environments/dev/terraform.tfvars"
```

---

## Production Readiness Features

### High Availability
- Multi-AZ deployment across availability zones
- Auto Scaling Groups for dynamic capacity
- Load balancing for traffic distribution

### Security
- Database encryption at rest
- Secrets management with AWS Secrets Manager
- Security groups with least privilege access
- VPC isolation with private subnets

### Monitoring & Backup
- CloudWatch integration for monitoring
- Automated database backups
- Performance Insights for RDS
- SNS notifications for alerts

### Cost Optimization
- Environment-specific resource sizing
- Conditional resource creation
- Spot instances for development
- Scheduled scaling policies

---

## Module Benefits

### For Development Teams
- **Faster deployment** - Reuse proven patterns
- **Consistency** - Same architecture across environments
- **Reduced errors** - Validated, tested modules
- **Easy scaling** - Parameterized configurations

### For Operations Teams
- **Standardization** - Consistent infrastructure patterns
- **Maintainability** - Centralized module updates
- **Compliance** - Built-in security and governance
- **Cost control** - Environment-appropriate sizing

---

## Next Steps

After understanding modular architecture:
1. **Practice** - Build your own modules
2. **Customize** - Adapt modules for your use cases
3. **Share** - Create a module library for your team
4. **Advanced patterns** - Explore complex compositions

---

## Key Takeaways

### Modular Design Benefits
- **Reusability** across environments and projects
- **Maintainability** through separation of concerns
- **Testability** of individual components
- **Collaboration** between team members

### Production Patterns
- **Environment-specific** configurations
- **Security-first** approach
- **Scalability** built-in from the start
- **Monitoring** and observability integrated

### Best Practices
- **Consistent naming** conventions
- **Variable validation** for safety
- **Structured outputs** for integration
- **Documentation** for team knowledge

---

This modular architecture approach transforms infrastructure management from manual, error-prone processes to automated, reliable, and scalable systems. The patterns demonstrated here form the foundation for enterprise-grade infrastructure as code.