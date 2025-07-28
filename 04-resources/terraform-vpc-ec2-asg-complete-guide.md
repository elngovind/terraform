# Terraform Complete Guide: VPC + EC2 with Auto Scaling Group
## Advanced Infrastructure as Code with Best Practices

---

## 🎯 Today's Learning Objectives

By the end of this session, you will:
- Build a complete AWS infrastructure with VPC, EC2, and ASG
- Master Terraform variables, parameters, and outputs
- Implement modular Terraform architecture
- Apply infrastructure best practices
- Understand advanced Terraform features

---

## 📋 What We're Building Today

```
AWS Infrastructure Architecture:
├── VPC (Virtual Private Cloud)
├── Public & Private Subnets (Multi-AZ)
├── Internet Gateway & Route Tables
├── Security Groups
├── Launch Template
├── Auto Scaling Group
├── Application Load Balancer
└── Outputs for integration
```

---

## 🏗️ Step-by-Step Implementation

### Step 1: Project Structure Setup

```bash
terraform-infrastructure/
├── main.tf              # Main configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── terraform.tfvars     # Variable values
├── modules/             # Reusable modules
│   ├── vpc/
│   ├── security/
│   └── compute/
└── environments/        # Environment configs
    ├── dev.tfvars
    └── prod.tfvars
```

---

### Step 2: Variables Configuration (variables.tf)

```hcl
# variables.tf
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "terraform-demo"
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "terraform-demo"
    ManagedBy   = "terraform"
    Owner       = "devops-team"
  }
}
```

**🔍 Key Learning Points:**
- **Validation blocks** ensure input correctness
- **Type constraints** prevent configuration errors
- **Default values** provide sensible fallbacks
- **Descriptions** make code self-documenting

---

### Step 3: VPC and Networking (main.tf - Part 1)

```hcl
# main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
  
  default_tags {
    tags = var.common_tags
  }
}

# Data source for AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"
    Type = "Public"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-subnet-${count.index + 1}"
    Type = "Private"
  })
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
  })
}

# Route Table Associations for Public Subnets
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
```

**🔍 Key Learning Points:**
- **Data sources** fetch existing AWS resources
- **Count parameter** creates multiple similar resources
- **Merge function** combines tag maps
- **String interpolation** creates dynamic names

---

### Step 4: Security Groups (main.tf - Part 2)

```hcl
# Security Group for ALB
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb-"
  vpc_id      = aws_vpc.main.id
  
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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for EC2 Instances
resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-${var.environment}-web-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-web-sg"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}
```

**🔍 Key Learning Points:**
- **name_prefix** avoids naming conflicts
- **Security group references** create dependencies
- **Lifecycle rules** control resource creation/destruction order

---

### Step 5: Launch Template and Auto Scaling Group (main.tf - Part 3)

```hcl
# Launch Template
resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-${var.environment}-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project_name = var.project_name
    environment  = var.environment
  }))
  
  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, {
      Name = "${var.project_name}-${var.environment}-web-instance"
    })
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
  
  enable_deletion_protection = false
  
  tags = var.common_tags
}

# Target Group
resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
  
  tags = var.common_tags
}

# Load Balancer Listener
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  name                = "${var.project_name}-${var.environment}-asg"
  vpc_zone_identifier = aws_subnet.private[*].id
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300
  
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity
  
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-asg"
    propagate_at_launch = true
  }
  
  dynamic "tag" {
    for_each = var.common_tags
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
```

**🔍 Key Learning Points:**
- **templatefile function** processes external files
- **Dynamic blocks** create repeated configurations
- **Splat expressions** (`[*]`) extract attributes from lists

---

### Step 6: User Data Script

```bash
# user_data.sh
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

# Create a simple web page
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>${project_name} - ${environment}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .header { background: #3498db; color: white; padding: 20px; border-radius: 5px; }
        .content { background: #f8f9fa; padding: 20px; margin-top: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 ${project_name}</h1>
            <p>Environment: ${environment}</p>
        </div>
        <div class="content">
            <h2>Server Information</h2>
            <p><strong>Instance ID:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
            <p><strong>Availability Zone:</strong> $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
            <p><strong>Instance Type:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-type)</p>
            <p><strong>Timestamp:</strong> $(date)</p>
        </div>
    </div>
</body>
</html>
EOF
```

---

### Step 7: Outputs Configuration (outputs.tf)

```hcl
# outputs.tf
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

output "auto_scaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.arn
}

output "security_group_ids" {
  description = "Security group IDs"
  value = {
    alb = aws_security_group.alb.id
    web = aws_security_group.web.id
  }
}

output "application_url" {
  description = "URL of the application"
  value       = "http://${aws_lb.main.dns_name}"
}

# Sensitive outputs
output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.web.id
  sensitive   = false
}
```

**🔍 Key Learning Points:**
- **Descriptive outputs** help with integration
- **Sensitive flag** protects confidential data
- **Complex output structures** organize related data

---

### Step 8: Environment-Specific Variables

```hcl
# dev.tfvars
project_name = "webapp"
environment  = "dev"
region       = "us-east-1"

# Smaller infrastructure for dev
instance_type    = "t3.micro"
min_size         = 1
max_size         = 2
desired_capacity = 1

common_tags = {
  Project     = "webapp"
  Environment = "dev"
  ManagedBy   = "terraform"
  Owner       = "dev-team"
  CostCenter  = "development"
}
```

```hcl
# prod.tfvars
project_name = "webapp"
environment  = "prod"
region       = "us-east-1"

# Production-ready infrastructure
instance_type    = "t3.small"
min_size         = 2
max_size         = 6
desired_capacity = 3

common_tags = {
  Project     = "webapp"
  Environment = "prod"
  ManagedBy   = "terraform"
  Owner       = "ops-team"
  CostCenter  = "production"
  Backup      = "required"
}
```

---

## 🚀 Advanced Terraform Features

### 1. Local Values for Complex Logic

```hcl
# locals.tf
locals {
  # Environment-specific configurations
  env_config = {
    dev = {
      instance_count = 1
      instance_type  = "t3.micro"
    }
    prod = {
      instance_count = 3
      instance_type  = "t3.medium"
    }
  }
  
  # Computed values
  current_config = local.env_config[var.environment]
  
  # Common naming convention
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Conditional logic
  enable_monitoring = var.environment == "prod" ? true : false
}
```

### 2. Conditional Resources

```hcl
# Create NAT Gateway only in production
resource "aws_nat_gateway" "main" {
  count = var.environment == "prod" ? length(aws_subnet.public) : 0
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-nat-${count.index + 1}"
  })
}
```

### 3. For Each with Maps

```hcl
# Create multiple security groups
variable "security_groups" {
  type = map(object({
    description = string
    ingress_rules = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
  }))
}

resource "aws_security_group" "custom" {
  for_each = var.security_groups
  
  name_prefix = "${local.name_prefix}-${each.key}-"
  description = each.value.description
  vpc_id      = aws_vpc.main.id
  
  dynamic "ingress" {
    for_each = each.value.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}
```

---

## 📁 Modular Architecture

### VPC Module Structure

```hcl
# modules/vpc/main.tf
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  
  tags = merge(var.tags, {
    Name = var.name
  })
}

# modules/vpc/variables.tf
variable "cidr_block" {
  description = "CIDR block for VPC"
  type        = string
}

variable "name" {
  description = "Name of the VPC"
  type        = string
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# modules/vpc/outputs.tf
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}
```

### Using Modules in Main Configuration

```hcl
# main.tf with modules
module "vpc" {
  source = "./modules/vpc"
  
  cidr_block = var.vpc_cidr
  name       = "${var.project_name}-${var.environment}-vpc"
  tags       = var.common_tags
}

module "compute" {
  source = "./modules/compute"
  
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnet_ids
  security_group_ids   = [module.security.web_sg_id]
  instance_type        = var.instance_type
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  
  tags = var.common_tags
}
```

---

## 🎯 Execution Commands

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Plan with specific environment
terraform plan -var-file="dev.tfvars"

# Apply configuration
terraform apply -var-file="dev.tfvars" -auto-approve

# Show current state
terraform show

# List all resources
terraform state list

# Get specific output
terraform output application_url

# Destroy infrastructure
terraform destroy -var-file="dev.tfvars" -auto-approve
```

---

## 🔧 Best Practices Implemented

### 1. **Security**
- Security groups with minimal required access
- Private subnets for application instances
- Load balancer in public subnets

### 2. **Scalability**
- Auto Scaling Group for dynamic scaling
- Multi-AZ deployment for high availability
- Load balancer for traffic distribution

### 3. **Maintainability**
- Modular architecture
- Consistent naming conventions
- Comprehensive tagging strategy

### 4. **Flexibility**
- Environment-specific configurations
- Variable validation
- Conditional resource creation

### 5. **Monitoring**
- Health checks on target groups
- CloudWatch integration (implicit)
- Proper tagging for cost allocation

---

## 🎓 Key Takeaways

### Variables & Parameters
- **Input validation** prevents configuration errors
- **Type constraints** ensure data consistency
- **Default values** provide sensible fallbacks
- **Environment-specific** configurations enable reusability

### Outputs
- **Structured outputs** facilitate integration
- **Sensitive data** protection
- **Documentation** through descriptions

### Modular Approach
- **Reusable components** reduce duplication
- **Clear interfaces** through variables and outputs
- **Separation of concerns** improves maintainability

### Advanced Features
- **Dynamic blocks** for flexible configurations
- **Local values** for complex computations
- **Conditional resources** for environment differences
- **For each** for resource iteration

---

## 🚀 Next Steps

1. **Implement monitoring** with CloudWatch alarms
2. **Add CI/CD pipeline** for automated deployments
3. **Implement state management** with remote backends
4. **Add secrets management** with AWS Secrets Manager
5. **Implement blue-green deployments**

---

## 📚 Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

---

**🎉 Congratulations!** You now have a production-ready, scalable, and maintainable infrastructure setup using Terraform best practices!