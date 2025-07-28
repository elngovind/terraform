# Terraform Quick Reference Cheat Sheet

## Essential Commands

### Initialization and Planning
```bash
terraform init          # Initialize working directory
terraform plan          # Preview changes
terraform apply         # Apply changes
terraform destroy       # Destroy infrastructure
terraform validate      # Validate configuration
terraform fmt           # Format code
```

### State Management
```bash
terraform show          # Show current state
terraform state list    # List resources in state
terraform state show    # Show specific resource
terraform refresh       # Update state from real infrastructure
```

### Workspace Management
```bash
terraform workspace list    # List workspaces
terraform workspace new     # Create workspace
terraform workspace select  # Switch workspace
```

---

## HCL Syntax Reference

### Resource Block
```hcl
resource "aws_instance" "example" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"
  
  tags = {
    Name = "example-instance"
  }
}
```

### Variable Declaration
```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
  
  validation {
    condition     = contains(["t3.micro", "t3.small"], var.instance_type)
    error_message = "Instance type must be t3.micro or t3.small."
  }
}
```

### Output Values
```hcl
output "instance_ip" {
  description = "Public IP of instance"
  value       = aws_instance.example.public_ip
  sensitive   = false
}
```

### Local Values
```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = "terraform-course"
  }
  
  name_prefix = "${var.project}-${var.environment}"
}
```

### Data Sources
```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
```

---

## Module Usage

### Module Block
```hcl
module "networking" {
  source = "./modules/networking"
  
  vpc_cidr    = var.vpc_cidr
  environment = var.environment
  
  tags = local.common_tags
}
```

### Module Structure
```
modules/networking/
├── main.tf       # Resources
├── variables.tf  # Input variables
├── outputs.tf    # Output values
└── README.md     # Documentation
```

---

## Built-in Functions

### String Functions
```hcl
upper("hello")           # "HELLO"
lower("HELLO")           # "hello"
title("hello world")     # "Hello World"
substr("hello", 1, 3)    # "ell"
```

### Collection Functions
```hcl
length([1, 2, 3])        # 3
contains(["a", "b"], "a") # true
keys({a = 1, b = 2})     # ["a", "b"]
values({a = 1, b = 2})   # [1, 2]
```

### Type Conversion
```hcl
tostring(123)            # "123"
tonumber("123")          # 123
tolist(["a", "b"])       # ["a", "b"]
tomap({a = 1})           # {a = 1}
```

### Date/Time Functions
```hcl
timestamp()              # Current timestamp
formatdate("YYYY-MM-DD", timestamp())
```

---

## Conditional Expressions

### Conditional
```hcl
condition ? true_val : false_val

# Example
instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"
```

### For Expressions
```hcl
# List comprehension
[for s in var.list : upper(s)]

# Map comprehension
{for k, v in var.map : k => upper(v)}

# Filtering
[for s in var.list : s if length(s) > 3]
```

---

## Variable Types

### Primitive Types
```hcl
variable "string_var" {
  type = string
}

variable "number_var" {
  type = number
}

variable "bool_var" {
  type = bool
}
```

### Collection Types
```hcl
variable "list_var" {
  type = list(string)
}

variable "map_var" {
  type = map(string)
}

variable "set_var" {
  type = set(string)
}
```

### Structural Types
```hcl
variable "object_var" {
  type = object({
    name = string
    age  = number
  })
}

variable "tuple_var" {
  type = tuple([string, number, bool])
}
```

---

## Common Patterns

### Environment-Specific Configuration
```hcl
locals {
  env_config = {
    dev = {
      instance_type = "t3.micro"
      min_size     = 1
    }
    prod = {
      instance_type = "t3.large"
      min_size     = 3
    }
  }
  
  config = local.env_config[var.environment]
}
```

### Resource Tagging
```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
}

resource "aws_instance" "example" {
  # ... other configuration ...
  
  tags = merge(local.common_tags, {
    Name = "example-instance"
    Role = "web-server"
  })
}
```

---

## Best Practices

### File Organization
- `main.tf` - Primary resources
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `locals.tf` - Local values
- `data.tf` - Data sources
- `versions.tf` - Provider requirements

### Naming Conventions
- Use snake_case for resources and variables
- Include environment in resource names
- Use descriptive names

### Security
- Never hardcode secrets
- Use sensitive variables for passwords
- Implement least privilege access

### State Management
- Use remote state for teams
- Enable state locking
- Regular backups

---

## Troubleshooting

### Common Errors
```bash
# Syntax errors
terraform validate

# Plan errors
terraform plan -detailed-exitcode

# State issues
terraform refresh
terraform state list
```

### Debug Mode
```bash
export TF_LOG=DEBUG
terraform apply
```

### Force Unlock State
```bash
terraform force-unlock LOCK_ID
```

---

This cheat sheet covers the most commonly used Terraform features and patterns. Keep it handy for quick reference!