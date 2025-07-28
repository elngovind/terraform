# Day 2 Lecture Notes: From Hardcoded to Parameterized Infrastructure
## Progressive EC2 Configuration with Advanced Terraform Concepts

**Duration:** 120 minutes | **Prerequisites:** Day 1 completed

---

## Learning Objectives

- Transform hardcoded EC2 configurations into flexible, parameterized infrastructure
- Master variables, data types, and validation through practical EC2 examples
- Implement dynamic expressions, functions, and conditionals
- Use .tfvars files for environment-specific EC2 deployments
- Apply production-ready patterns to EC2 infrastructure

---

## Quick Recap - Day 1 Summary

### What We Learned
1. **Infrastructure as Code** - Manual setup vs automated deployment
2. **Terraform Workflow** - init, plan, apply, destroy
3. **Basic HCL** - Resources, providers, simple configurations
4. **First EC2 Instance** - Hardcoded AMI, instance type, basic deployment

### Today's Mission
Transform this basic EC2 from Day 1 into a flexible, production-ready configuration that can adapt to different environments and requirements.

---

## Step 1: Starting Point - Hardcoded EC2 (10 minutes)

Let's begin with a simple, hardcoded EC2 instance (similar to Day 1):

### Create Project Directory
```bash
mkdir terraform-ec2-evolution
cd terraform-ec2-evolution
```

### main.tf - Hardcoded Version
```hcl
# Provider configuration
provider "aws" {
  region = "us-east-1"
}

# Hardcoded EC2 instance
resource "aws_instance" "web" {
  ami           = "ami-0c02fb55956c7d316"  # Amazon Linux 2
  instance_type = "t2.micro"
  
  tags = {
    Name = "my-web-server"
  }
}

# Output the public IP
output "instance_ip" {
  value = aws_instance.web.public_ip
}
```

### Deploy the Hardcoded Version
```bash
terraform init
terraform plan
terraform apply
```

**Problems with this approach:**
- AMI ID is hardcoded (won't work in different regions)
- Instance type is fixed
- Can't easily change for different environments
- No flexibility for scaling or modifications

---

## Step 2: Introducing Variables - Making EC2 Flexible (15 minutes)

Let's make our EC2 instance configurable using variables.

### variables.tf - Define Input Variables
```hcl
# Region variable
variable "region" {
  description = "AWS region for EC2 deployment"
  type        = string
  default     = "us-east-1"
}

# Instance type variable
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

# Instance name variable
variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "terraform-web-server"
}

# Environment variable
variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}
```

### main.tf - Using Variables
```hcl
# Provider using variable
provider "aws" {
  region = var.region
}

# Data source to get latest Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# EC2 instance using variables
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  
  tags = {
    Name        = var.instance_name
    Environment = var.environment
  }
}
```

### outputs.tf - Structured Outputs
```hcl
output "instance_details" {
  description = "EC2 instance information"
  value = {
    id         = aws_instance.web.id
    public_ip  = aws_instance.web.public_ip
    private_ip = aws_instance.web.private_ip
    ami_id     = aws_instance.web.ami
    type       = aws_instance.web.instance_type
  }
}

output "instance_url" {
  description = "URL to access the instance"
  value       = "http://${aws_instance.web.public_ip}"
}
```

### Test the Parameterized Version
```bash
# Plan with default values
terraform plan

# Apply with custom values
terraform apply -var="instance_type=t3.small" -var="instance_name=my-custom-server"
```

**Benefits achieved:**
- Dynamic AMI selection (works in any region)
- Configurable instance type
- Flexible naming
- Environment awareness

---

## Step 3: Variable Validation - Making EC2 Configuration Safe (10 minutes)

Add validation to ensure only valid values are used for our EC2 instance.

### Enhanced variables.tf with Validation
```hcl
variable "region" {
  description = "AWS region for EC2 deployment"
  type        = string
  default     = "us-east-1"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.region))
    error_message = "Region must be a valid AWS region identifier."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
  
  validation {
    condition = contains([
      "t2.micro", "t2.small", "t2.medium",
      "t3.micro", "t3.small", "t3.medium"
    ], var.instance_type)
    error_message = "Instance type must be a valid EC2 type from the allowed list."
  }
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "terraform-web-server"
  
  validation {
    condition     = length(var.instance_name) > 0 && length(var.instance_name) <= 255
    error_message = "Instance name must be between 1 and 255 characters."
  }
}
```

### Test Validation
```bash
# This will fail validation
terraform plan -var="instance_type=invalid-type"

# This will pass validation
terraform plan -var="instance_type=t3.small"
```

---

## Step 4: Data Types and Complex Variables (15 minutes)

Let's explore different data types using EC2 configuration examples.

### Advanced variables.tf with Different Data Types
```hcl
# String variable (we already have these)
variable "instance_name" {
  type = string
  default = "web-server"
}

# Number variable for instance count
variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 1
  
  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

# Boolean variable for monitoring
variable "enable_monitoring" {
  description = "Enable detailed monitoring for EC2 instances"
  type        = bool
  default     = false
}

# List variable for security group ports
variable "allowed_ports" {
  description = "List of ports to allow in security group"
  type        = list(number)
  default     = [80, 443, 22]
}

# Map variable for instance types per environment
variable "instance_types" {
  description = "Instance types for different environments"
  type        = map(string)
  default = {
    dev     = "t2.micro"
    staging = "t2.small"
    prod    = "t3.medium"
  }
}

# Object variable for EC2 configuration
variable "ec2_config" {
  description = "EC2 instance configuration"
  type = object({
    instance_type    = string
    monitoring       = bool
    backup_required  = bool
    storage_size     = number
  })
  default = {
    instance_type   = "t2.micro"
    monitoring      = false
    backup_required = false
    storage_size    = 8
  }
}
```

### Using Complex Variables in main.tf
```hcl
# Security group using list variable
resource "aws_security_group" "web" {
  name_prefix = "${var.instance_name}-sg"
  
  # Dynamic ingress rules using list
  dynamic "ingress" {
    for_each = var.allowed_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.instance_name}-sg"
  }
}

# EC2 instances using count and map variables
resource "aws_instance" "web" {
  count = var.instance_count
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_types[var.environment]
  
  vpc_security_group_ids = [aws_security_group.web.id]
  monitoring             = var.enable_monitoring
  
  # Root block device using object variable
  root_block_device {
    volume_size = var.ec2_config.storage_size
    volume_type = "gp3"
    encrypted   = true
  }
  
  tags = {
    Name        = "${var.instance_name}-${count.index + 1}"
    Environment = var.environment
    Monitoring  = var.enable_monitoring
    Backup      = var.ec2_config.backup_required
  }
}
```

---

## Step 5: Conditional Logic - Environment-Specific EC2 Behavior (15 minutes)

Add conditional logic to make EC2 instances behave differently based on environment.

### Conditional Expressions in main.tf
```hcl
# Local values for environment-specific logic
locals {
  # Environment-specific configurations
  env_config = {
    dev = {
      instance_count   = 1
      instance_type    = "t2.micro"
      monitoring       = false
      backup_enabled   = false
      storage_size     = 8
    }
    staging = {
      instance_count   = 2
      instance_type    = "t2.small"
      monitoring       = true
      backup_enabled   = true
      storage_size     = 16
    }
    prod = {
      instance_count   = 3
      instance_type    = "t3.medium"
      monitoring       = true
      backup_enabled   = true
      storage_size     = 32
    }
  }
  
  # Current environment configuration
  current_config = local.env_config[var.environment]
  
  # Common tags
  common_tags = {
    Environment = var.environment
    Project     = "terraform-learning"
    ManagedBy   = "terraform"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
}

# EC2 instances with conditional configuration
resource "aws_instance" "web" {
  count = local.current_config.instance_count
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = local.current_config.instance_type
  
  vpc_security_group_ids = [aws_security_group.web.id]
  monitoring             = local.current_config.monitoring
  
  root_block_device {
    volume_size = local.current_config.storage_size
    volume_type = "gp3"
    encrypted   = var.environment == "prod" ? true : false
  }
  
  # Conditional user data (install monitoring agent only in prod)
  user_data = var.environment == "prod" ? base64encode(file("user_data_prod.sh")) : base64encode(file("user_data_dev.sh"))
  
  tags = merge(local.common_tags, {
    Name = "${var.instance_name}-${var.environment}-${count.index + 1}"
    Tier = "web"
  })
}

# Conditional CloudWatch alarms (only for production)
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = var.environment == "prod" ? local.current_config.instance_count : 0
  
  alarm_name          = "${var.instance_name}-high-cpu-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  
  dimensions = {
    InstanceId = aws_instance.web[count.index].id
  }
  
  tags = local.common_tags
}

# Conditional backup (only for staging and prod)
resource "aws_backup_vault" "ec2_backup" {
  count = contains(["staging", "prod"], var.environment) ? 1 : 0
  
  name        = "${var.instance_name}-backup-vault"
  kms_key_arn = aws_kms_key.backup[0].arn
  
  tags = local.common_tags
}
```

---

## Step 6: Functions and Expressions (10 minutes)

Use Terraform functions to make EC2 configuration more dynamic.

### Functions in Action
```hcl
# Using functions for dynamic configuration
locals {
  # String functions
  instance_name_upper = upper(var.instance_name)
  instance_name_clean = replace(var.instance_name, "_", "-")
  
  # Collection functions
  total_instances = length(aws_instance.web)
  port_count      = length(var.allowed_ports)
  
  # Conditional functions
  storage_size = var.environment == "prod" ? 50 : 20
  
  # Date functions
  deployment_date = formatdate("YYYY-MM-DD", timestamp())
  
  # Network functions (for advanced scenarios)
  subnet_cidrs = [for i in range(3) : cidrsubnet("10.0.0.0/16", 8, i)]
}

# Using functions in resource configuration
resource "aws_instance" "web" {
  count = local.current_config.instance_count
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = local.current_config.instance_type
  
  tags = {
    Name         = "${local.instance_name_clean}-${var.environment}-${format("%02d", count.index + 1)}"
    Environment  = upper(var.environment)
    DeployedOn   = local.deployment_date
    InstanceNum  = "${count.index + 1} of ${local.current_config.instance_count}"
  }
}
```

---

## Step 7: .tfvars Files - Environment-Specific EC2 Deployments (15 minutes)

Create environment-specific configuration files for our EC2 infrastructure.

### dev.tfvars
```hcl
# Development environment configuration
region        = "us-east-1"
environment   = "dev"
instance_name = "dev-web-server"

# Development-specific settings
instance_count   = 1
enable_monitoring = false
allowed_ports    = [80, 22, 8080]  # Extra port for development

# Development EC2 configuration
ec2_config = {
  instance_type   = "t2.micro"
  monitoring      = false
  backup_required = false
  storage_size    = 8
}

instance_types = {
  dev     = "t2.micro"
  staging = "t2.small"
  prod    = "t3.medium"
}
```

### staging.tfvars
```hcl
# Staging environment configuration
region        = "us-east-1"
environment   = "staging"
instance_name = "staging-web-server"

# Staging-specific settings
instance_count   = 2
enable_monitoring = true
allowed_ports    = [80, 443, 22]

# Staging EC2 configuration
ec2_config = {
  instance_type   = "t2.small"
  monitoring      = true
  backup_required = true
  storage_size    = 16
}

instance_types = {
  dev     = "t2.micro"
  staging = "t2.small"
  prod    = "t3.medium"
}
```

### prod.tfvars
```hcl
# Production environment configuration
region        = "us-west-2"  # Different region for prod
environment   = "prod"
instance_name = "prod-web-server"

# Production-specific settings
instance_count   = 3
enable_monitoring = true
allowed_ports    = [80, 443]  # Only necessary ports

# Production EC2 configuration
ec2_config = {
  instance_type   = "t3.medium"
  monitoring      = true
  backup_required = true
  storage_size    = 32
}

instance_types = {
  dev     = "t2.micro"
  staging = "t2.small"
  prod    = "t3.medium"
}
```

---

## Step 8: Terraform Console - Testing EC2 Expressions (10 minutes)

Use Terraform console to test expressions before applying them.

### Console Examples
```bash
# Start Terraform console
terraform console

# Test variable access
> var.instance_name
"terraform-web-server"

# Test environment-specific logic
> var.environment == "prod" ? "t3.large" : "t2.micro"
"t2.micro"

# Test list operations
> length(var.allowed_ports)
3

# Test map access
> var.instance_types["prod"]
"t3.medium"

# Test functions
> upper(var.environment)
"DEV"

# Test complex expressions
> [for port in var.allowed_ports : "Port ${port}"]
[
  "Port 80",
  "Port 443", 
  "Port 22"
]

# Test conditional logic
> var.environment == "prod" ? 3 : 1
1
```

---

## Step 9: Deployment with Different Configurations (10 minutes)

Deploy the same EC2 infrastructure with different configurations.

### Deploy Development Environment
```bash
# Plan development deployment
terraform plan -var-file="dev.tfvars"

# Apply development configuration
terraform apply -var-file="dev.tfvars"

# Check outputs
terraform output
```

### Deploy Staging Environment
```bash
# Switch to staging workspace (optional)
terraform workspace new staging
terraform workspace select staging

# Plan staging deployment
terraform plan -var-file="staging.tfvars"

# Apply staging configuration
terraform apply -var-file="staging.tfvars"
```

### Compare Environments
```bash
# Compare what would be different in production
terraform plan -var-file="prod.tfvars"

# Notice the differences:
# - Different region
# - More instances
# - Larger instance types
# - Additional monitoring
# - Backup enabled
```

---

## Step 10: Variable Precedence Testing (10 minutes)

Understand how Terraform resolves variable values.

### Variable Precedence Order (highest to lowest)
1. Command line `-var` flags
2. Command line `-var-file` flags
3. Environment variables (`TF_VAR_name`)
4. `terraform.tfvars` or `*.auto.tfvars`
5. Default values in `variables.tf`

### Testing Precedence
```bash
# Set environment variable
export TF_VAR_instance_type="t3.small"

# This will use t3.small from environment variable
terraform plan -var-file="dev.tfvars"

# This will override with t2.medium from command line
terraform plan -var-file="dev.tfvars" -var="instance_type=t2.medium"

# Clean up environment variable
unset TF_VAR_instance_type
```

---

## Key Concepts Summary

### Evolution of Our EC2 Configuration

1. **Hardcoded** → Fixed AMI, instance type, region
2. **Variables** → Flexible configuration with defaults
3. **Validation** → Safe input values
4. **Data Types** → Complex configurations (lists, maps, objects)
5. **Conditionals** → Environment-specific behavior
6. **Functions** → Dynamic value computation
7. **.tfvars** → Environment separation
8. **Console** → Expression testing
9. **Precedence** → Variable resolution understanding

### Production-Ready Patterns Achieved

- **Environment Separation** - Different configs for dev/staging/prod
- **Input Validation** - Prevent invalid configurations
- **Conditional Resources** - Environment-specific features
- **Dynamic Configuration** - Computed values and expressions
- **Flexible Deployment** - Same code, different environments

---

## Next Steps

Now that you understand how to parameterize EC2 infrastructure:

1. **Practice** - Try different variable combinations
2. **Extend** - Add more conditional logic
3. **Modularize** - Convert to reusable modules
4. **Scale** - Apply patterns to complex infrastructure

---

## Cleanup

```bash
# Destroy all environments
terraform destroy -var-file="dev.tfvars"
terraform workspace select staging
terraform destroy -var-file="staging.tfvars"
```

---

**You've successfully transformed a simple, hardcoded EC2 instance into a flexible, parameterized, production-ready infrastructure configuration!**

This progression from hardcoded to parameterized infrastructure demonstrates the power of Terraform's variable system and prepares you for building complex, reusable infrastructure as code.