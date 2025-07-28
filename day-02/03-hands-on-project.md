# Day 2 Hands-On Project: Parametrized Infrastructure
## Building Dynamic EC2 + VPC with Variables and Loops

**Duration:** 90 minutes | **Prerequisites:** Day 2 lecture completed

---

## Project Overview

Build a parametrized infrastructure that demonstrates:
- HCL blocks, arguments, and expressions
- Input and output variables
- Terraform data types (string, number, list, map, object)
- Dynamic expressions with loops (count, for_each)
- Environment-specific configurations using .tfvars

---

## Architecture

```
Parametrized Infrastructure:
├── VPC with configurable CIDR
├── Multiple public subnets (using for_each)
├── Multiple EC2 instances (using object list)
├── Dynamic tagging and naming
└── Environment-specific sizing
```

---

## Project Structure

```
terraform-variables-demo/
├── main.tf              # All resource definitions
├── variables.tf         # Input variable declarations
├── outputs.tf           # Output variables
├── dev.tfvars           # Development environment values
├── prod.tfvars          # Production environment values
└── terraform.tfvars     # Default values
```

---

## Step 1: Define Input Variables (15 minutes)

Create `variables.tf` with comprehensive variable definitions:

```hcl
# String variable for AWS region
variable "region" {
  type        = string
  description = "AWS region where infrastructure will be deployed"
  default     = "us-east-1"
}

# EC2 AMI ID passed from tfvars
variable "ami_id" {
  type        = string
  description = "AMI ID for EC2 instance"
}

# EC2 instance type with validation
variable "instance_type" {
  type        = string
  description = "EC2 instance type to be used"
  default     = "t2.micro"
  
  validation {
    condition     = contains(["t2.micro", "t2.small", "t3.micro", "t3.small", "t3.medium"], var.instance_type)
    error_message = "Instance type must be a valid EC2 type."
  }
}

# VPC CIDR block
variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for the VPC"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

# List of subnet CIDRs for for_each loop
variable "public_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  description = "CIDRs for public subnets to be created"
}

# Map for environment-specific configurations
variable "env_config" {
  type = map(object({
    instance_count = number
    instance_type  = string
    monitoring     = bool
  }))
  default = {
    dev = {
      instance_count = 1
      instance_type  = "t2.micro"
      monitoring     = false
    }
    prod = {
      instance_count = 3
      instance_type  = "t3.medium"
      monitoring     = true
    }
  }
  description = "Environment-specific configurations"
}

# Common tags applied to all resources
variable "tags" {
  type        = map(string)
  default     = {
    Owner   = "DevOps Team"
    Project = "TerraformTraining"
  }
  description = "Common tags for all resources"
}

# Environment string
variable "env" {
  type        = string
  default     = "dev"
  description = "Environment type (dev, staging, prod)"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Object list for named EC2 instances
variable "instances" {
  type = list(object({
    name = string
    type = string
  }))
  default = [
    { name = "web1", type = "web" },
    { name = "web2", type = "web" },
    { name = "app1", type = "app" }
  ]
  description = "List of EC2 instances to launch with their names and types"
}
```

---

## Step 2: Create Main Infrastructure (30 minutes)

Create `main.tf` with dynamic resource definitions:

```hcl
# Provider configuration using variable
provider "aws" {
  region = var.region
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC using variable
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.env}-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.env}-igw"
  })
}

# Public subnets using for_each loop
resource "aws_subnet" "public" {
  for_each = toset(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = data.aws_availability_zones.available.names[index(var.public_subnet_cidrs, each.value)]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.env}-public-subnet-${index(var.public_subnet_cidrs, each.value) + 1}"
    Type = "Public"
  })
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.env}-public-rt"
  })
}

# Route table associations
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Security group with dynamic rules
resource "aws_security_group" "web" {
  name_prefix = "${var.env}-web-"
  vpc_id      = aws_vpc.main.id

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.env}-web-sg"
  })
}

# EC2 instances using for_each with object list
resource "aws_instance" "web" {
  for_each = {
    for i, inst in var.instances :
    inst.name => inst
  }

  ami                    = var.ami_id
  instance_type          = var.env_config[var.env].instance_type
  subnet_id              = values(aws_subnet.public)[0].id
  vpc_security_group_ids = [aws_security_group.web.id]

  # User data script
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    instance_name = each.key
    instance_type = each.value.type
  }))

  tags = merge(var.tags, {
    Name        = "${var.env}-${each.key}"
    Environment = var.env
    Type        = each.value.type
  })
}

# Conditional resource - CloudWatch monitoring for production
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  for_each = var.env_config[var.env].monitoring ? aws_instance.web : {}

  alarm_name          = "${each.key}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"

  dimensions = {
    InstanceId = each.value.id
  }

  tags = var.tags
}
```

Create `user_data.sh` script:

```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>${instance_name}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { background-color: #232f3e; color: white; padding: 20px; }
        .content { padding: 20px; }
        .info { background-color: #f0f0f0; padding: 15px; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Terraform Demo Server</h1>
    </div>
    <div class="content">
        <div class="info">
            <h3>Server Information</h3>
            <p><strong>Instance Name:</strong> ${instance_name}</p>
            <p><strong>Instance Type:</strong> ${instance_type}</p>
            <p><strong>Hostname:</strong> $(hostname)</p>
            <p><strong>IP Address:</strong> $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)</p>
        </div>
        <div class="info">
            <h3>Terraform Variables Demo</h3>
            <p>This server was created using Terraform with:</p>
            <ul>
                <li>Dynamic variable configuration</li>
                <li>for_each loops for multiple resources</li>
                <li>Environment-specific settings</li>
                <li>Conditional resource creation</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF
```

---

## Step 3: Define Outputs (10 minutes)

Create `outputs.tf` to return useful information:

```hcl
# VPC information
output "vpc_id" {
  description = "The ID of the created VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# Subnet information using for expression
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [for s in aws_subnet.public : s.id]
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = [for s in aws_subnet.public : s.cidr_block]
}

# Instance information
output "instance_details" {
  description = "Detailed information about EC2 instances"
  value = {
    for name, instance in aws_instance.web : name => {
      id        = instance.id
      public_ip = instance.public_ip
      private_ip = instance.private_ip
      type      = instance.instance_type
    }
  }
}

output "instance_public_ips" {
  description = "List of EC2 instance public IPs"
  value       = [for i in aws_instance.web : i.public_ip]
}

output "web_urls" {
  description = "URLs to access web servers"
  value       = [for name, instance in aws_instance.web : "http://${instance.public_ip}"]
}

# Environment configuration used
output "environment_config" {
  description = "Configuration used for current environment"
  value       = var.env_config[var.env]
}
```

---

## Step 4: Create Environment Files (10 minutes)

Create `dev.tfvars`:

```hcl
# Development environment configuration
region        = "us-east-1"
ami_id        = "ami-0c02fb55956c7d316"  # Amazon Linux 2
instance_type = "t2.micro"
env           = "dev"

vpc_cidr = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]

instances = [
  { name = "web1", type = "web" }
]

tags = {
  Owner       = "DevOps Team"
  Project     = "TerraformTraining"
  Environment = "development"
  CostCenter  = "engineering"
}
```

Create `prod.tfvars`:

```hcl
# Production environment configuration
region        = "us-west-2"
ami_id        = "ami-0c02fb55956c7d316"  # Amazon Linux 2
instance_type = "t3.medium"
env           = "prod"

vpc_cidr = "10.1.0.0/16"
public_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]

instances = [
  { name = "web1", type = "web" },
  { name = "web2", type = "web" },
  { name = "app1", type = "app" }
]

tags = {
  Owner       = "DevOps Team"
  Project     = "TerraformTraining"
  Environment = "production"
  CostCenter  = "engineering"
  Backup      = "required"
}
```

---

## Step 5: Deploy and Test (20 minutes)

### Initialize and Deploy Development

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan with development configuration
terraform plan -var-file="dev.tfvars"

# Apply development environment
terraform apply -var-file="dev.tfvars"
```

### Test Terraform Console

```bash
# Open Terraform console
terraform console

# Test expressions
> var.instances
> length(var.public_subnet_cidrs)
> var.env_config["dev"]
> upper(var.env)
```

### Verify Infrastructure

```bash
# Check outputs
terraform output

# Test web servers
curl $(terraform output -raw web_urls | jq -r '.[0]')

# List all resources
terraform state list
```

### Compare Environments

```bash
# Plan production (don't apply)
terraform plan -var-file="prod.tfvars"

# See the differences in resource count and configuration
```

---

## Step 6: Advanced Exercises (15 minutes)

### Exercise 1: Add Conditional Resources

Add a load balancer that only creates in production:

```hcl
# Application Load Balancer (only for production)
resource "aws_lb" "main" {
  count              = var.env == "prod" ? 1 : 0
  name               = "${var.env}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = [for s in aws_subnet.public : s.id]

  tags = var.tags
}
```

### Exercise 2: Dynamic Security Group Rules

Create security group rules based on environment:

```hcl
locals {
  # Different ports for different environments
  allowed_ports = var.env == "prod" ? [80, 443] : [80, 8080, 3000]
}

resource "aws_security_group_rule" "web_ingress" {
  for_each = toset([for port in local.allowed_ports : tostring(port)])

  type              = "ingress"
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web.id
}
```

### Exercise 3: Variable Override Testing

Test variable precedence:

```bash
# Test CLI override
terraform plan -var-file="dev.tfvars" -var="instance_type=t3.small"

# Test environment variable
export TF_VAR_instance_type=t2.small
terraform plan -var-file="dev.tfvars"
```

---

## Cleanup

```bash
# Destroy development environment
terraform destroy -var-file="dev.tfvars"

# Confirm destruction
terraform state list
```

---

## Key Concepts Demonstrated

### HCL Features Used
- **Blocks:** resource, variable, output, data
- **Arguments:** All resource configurations
- **Expressions:** String interpolation, conditionals, functions

### Variable Types Implemented
- **string:** region, ami_id, env
- **number:** Via env_config object
- **bool:** monitoring flags
- **list(string):** public_subnet_cidrs
- **map:** tags, env_config
- **object:** Complex configurations
- **list(object):** instances

### Dynamic Features
- **for_each:** Subnets, instances, security group rules
- **count:** Conditional resources (ALB, monitoring)
- **Conditionals:** Environment-based logic
- **Functions:** merge(), toset(), values(), index()

### Best Practices Shown
- Variable validation
- Environment separation
- Dynamic tagging
- Resource naming conventions
- Output organization

---

## Lab Completion Checklist

- [ ] All variable types implemented and tested
- [ ] for_each loops working for subnets and instances
- [ ] Conditional resources based on environment
- [ ] .tfvars files for different environments
- [ ] Terraform console expressions tested
- [ ] Infrastructure deployed and verified
- [ ] Web servers accessible via outputs
- [ ] Variable precedence understood
- [ ] Resources cleaned up properly

---

**Congratulations! You've built a sophisticated, parametrized infrastructure using advanced Terraform features!**

*This project demonstrates production-ready patterns for dynamic, environment-aware infrastructure as code.*