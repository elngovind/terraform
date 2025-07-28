# Day 2 Lecture Notes: Modular Architecture & Best Practices
## Advanced Terraform Concepts

**Duration:** 90 minutes | **Prerequisites:** Day 1 completed

---

## Learning Objectives

- Master variables, outputs, and locals
- Understand module creation and usage
- Implement environment-specific configurations
- Apply production-ready patterns
- Design scalable infrastructure architecture

---

## 1. Variables Deep Dive (20 minutes)

### Variable Types and Validation

```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_config" {
  description = "Instance configuration"
  type = object({
    type = string
    ami  = string
  })
  
  default = {
    type = "t3.micro"
    ami  = "ami-0abcdef1234567890"
  }
}
```

### Variable Precedence
1. Command line flags (`-var`)
2. Variable files (`terraform.tfvars`)
3. Environment variables (`TF_VAR_name`)
4. Default values in configuration

---

## 2. Outputs and Data Flow (15 minutes)

### Output Values
```hcl
output "instance_ip" {
  description = "Public IP of the instance"
  value       = aws_instance.web.public_ip
  sensitive   = false
}

output "database_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}
```

### Using Outputs
- Share data between configurations
- Display important information
- Input to other modules

---

## 3. Local Values (10 minutes)

### Computing Values
```hcl
locals {
  # Environment-specific configurations
  env_config = {
    dev = {
      instance_type = "t3.micro"
      min_size     = 1
      max_size     = 2
    }
    prod = {
      instance_type = "t3.large"
      min_size     = 3
      max_size     = 10
    }
  }
  
  current_config = local.env_config[var.environment]
  
  # Common tags
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}
```

---

## 4. Module Architecture (25 minutes)

### Why Modules?
- **Reusability**: Write once, use many times
- **Organization**: Logical grouping of resources
- **Abstraction**: Hide complexity
- **Testing**: Easier to test smaller components

### Module Structure
```
modules/
├── networking/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
├── compute/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── database/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

### Creating a Module
```hcl
# modules/networking/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

# modules/networking/variables.tf
variable "vpc_cidr" {
  description = "CIDR block for VPC"
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

# modules/networking/outputs.tf
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}
```

### Using Modules
```hcl
module "networking" {
  source = "./modules/networking"
  
  vpc_cidr    = var.vpc_cidr
  name_prefix = local.name_prefix
  tags        = local.common_tags
}

module "compute" {
  source = "./modules/compute"
  
  vpc_id          = module.networking.vpc_id
  subnet_ids      = module.networking.private_subnet_ids
  security_groups = module.security.web_sg_id
  
  instance_type = local.current_config.instance_type
  min_size     = local.current_config.min_size
  max_size     = local.current_config.max_size
}
```

---

## 5. Environment Management (15 minutes)

### Directory Structure
```
environments/
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

### Environment-Specific Variables
```hcl
# environments/dev/terraform.tfvars
environment = "dev"
vpc_cidr    = "10.0.0.0/16"
project_name = "ecommerce"

# environments/prod/terraform.tfvars
environment = "prod"
vpc_cidr    = "10.1.0.0/16"
project_name = "ecommerce"
```

---

## 6. Best Practices (15 minutes)

### Naming Conventions
- Use consistent naming patterns
- Include environment in resource names
- Use descriptive variable names

### Code Organization
- One resource type per file when possible
- Group related resources logically
- Use modules for reusable components

### Security
- Never hardcode secrets
- Use sensitive variables appropriately
- Implement least privilege access

### State Management
- Use remote state for team collaboration
- Enable state locking
- Regular state backups

---

## Key Takeaways

1. **Variables** provide flexibility and reusability
2. **Outputs** enable data sharing between modules
3. **Locals** help with computed values and DRY principle
4. **Modules** are essential for scalable infrastructure
5. **Environment separation** enables safe deployments
6. **Best practices** ensure maintainable code

---

## Next Session

In the next session, we'll apply these concepts by creating a complete modular architecture for an e-commerce platform.

**Continue to:** [Modular Guide](02-modular-guide.md)