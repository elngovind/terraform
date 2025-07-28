# Day 2: Simple Modular Demo
## Step-by-Step Introduction to Terraform Modules

**Duration:** 45 minutes | **Prerequisites:** Day 2 lecture completed

---

## Overview

Before diving into complex infrastructure, let's build a simple modular project step-by-step. This demo introduces module concepts gradually, making it easy to understand before tackling advanced patterns.

---

## What We'll Build

```
Simple Web Application:
├── VPC with public subnet
├── Security group for web access
├── EC2 instance running web server
└── Outputs for accessing the application
```

**Learning Goals:**
- Create your first Terraform module
- Understand module inputs and outputs
- Use modules in root configuration
- Pass data between modules

---

## Project Structure

```
simple-web-app/
├── main.tf              # Root configuration
├── variables.tf         # Root variables
├── outputs.tf           # Root outputs
├── terraform.tfvars     # Variable values
└── modules/
    ├── networking/      # VPC and subnet module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── security/        # Security group module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── compute/         # EC2 instance module
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── user_data.sh
```

---

## Step 1: Create Project Directory (5 minutes)

```bash
# Create project structure
mkdir -p simple-web-app/modules/{networking,security,compute}
cd simple-web-app

# Create all necessary files
touch main.tf variables.tf outputs.tf terraform.tfvars
touch modules/networking/{main.tf,variables.tf,outputs.tf}
touch modules/security/{main.tf,variables.tf,outputs.tf}
touch modules/compute/{main.tf,variables.tf,outputs.tf,user_data.sh}
```

---

## Step 2: Build Networking Module (10 minutes)

### modules/networking/variables.tf
```hcl
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}
```

### modules/networking/main.tf
```hcl
# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Create public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Create route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Associate route table with subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```

### modules/networking/outputs.tf
```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}
```

---

## Step 3: Build Security Module (8 minutes)

### modules/security/variables.tf
```hcl
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "allowed_ports" {
  description = "List of allowed ports"
  type        = list(number)
  default     = [80, 22]
}
```

### modules/security/main.tf
```hcl
# Create security group for web server
resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-web-"
  description = "Security group for web server"
  vpc_id      = var.vpc_id

  # Dynamic ingress rules for allowed ports
  dynamic "ingress" {
    for_each = var.allowed_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

### modules/security/outputs.tf
```hcl
output "security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}
```

---

## Step 4: Build Compute Module (12 minutes)

### modules/compute/variables.tf
```hcl
variable "ami_id" {
  description = "AMI ID for the instance"
  type        = string
}

variable "instance_type" {
  description = "Type of EC2 instance"
  type        = string
  default     = "t2.micro"
}

variable "subnet_id" {
  description = "ID of the subnet"
  type        = string
}

variable "security_group_id" {
  description = "ID of the security group"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}
```

### modules/compute/user_data.sh
```bash
#!/bin/bash
yum update -y
yum install -y httpd

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create a simple web page
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Simple Terraform Demo</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 40px; 
            background-color: #f0f0f0;
        }
        .container { 
            background: white; 
            padding: 30px; 
            border-radius: 10px; 
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 { color: #333; }
        .info { 
            background: #e7f3ff; 
            padding: 15px; 
            border-radius: 5px; 
            margin: 10px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to Simple Terraform Demo!</h1>
        <div class="info">
            <h3>Server Information:</h3>
            <p><strong>Instance ID:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
            <p><strong>Availability Zone:</strong> $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
            <p><strong>Instance Type:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-type)</p>
        </div>
        <div class="info">
            <h3>Module Demo Success!</h3>
            <p>This web server was created using Terraform modules:</p>
            <ul>
                <li>Networking module created the VPC and subnet</li>
                <li>Security module created the security group</li>
                <li>Compute module created this EC2 instance</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF

# Set proper permissions
chown apache:apache /var/www/html/index.html
```

### modules/compute/main.tf
```hcl
# Create EC2 instance
resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]

  # User data script
  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name = "${var.project_name}-web-server"
  }
}
```

### modules/compute/outputs.tf
```hcl
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.web.public_dns
}
```

---

## Step 5: Create Root Configuration (8 minutes)

### variables.tf
```hcl
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "simple-web-demo"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
```

### main.tf
```hcl
# Configure AWS provider
provider "aws" {
  region = var.region
}

# Get latest Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Use networking module
module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  vpc_cidr     = "10.0.0.0/16"
  subnet_cidr  = "10.0.1.0/24"
}

# Use security module
module "security" {
  source = "./modules/security"

  vpc_id       = module.networking.vpc_id
  project_name = var.project_name
  allowed_ports = [80, 22]
}

# Use compute module
module "compute" {
  source = "./modules/compute"

  ami_id            = data.aws_ami.amazon_linux.id
  instance_type     = var.instance_type
  subnet_id         = module.networking.subnet_id
  security_group_id = module.security.security_group_id
  project_name      = var.project_name
}
```

### outputs.tf
```hcl
# Networking outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

# Security outputs
output "security_group_id" {
  description = "ID of the security group"
  value       = module.security.security_group_id
}

# Compute outputs
output "instance_info" {
  description = "EC2 instance information"
  value = {
    id         = module.compute.instance_id
    public_ip  = module.compute.public_ip
    public_dns = module.compute.public_dns
  }
}

# Application URL
output "web_url" {
  description = "URL to access the web application"
  value       = "http://${module.compute.public_ip}"
}
```

### terraform.tfvars
```hcl
project_name  = "my-first-modules"
region        = "us-east-1"
instance_type = "t2.micro"
```

---

## Step 6: Deploy and Test (7 minutes)

### Initialize and Deploy
```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan

# Apply configuration
terraform apply
```

### Test the Application
```bash
# Get the web URL
terraform output web_url

# Test with curl
curl $(terraform output -raw web_url)

# Or open in browser
open $(terraform output -raw web_url)
```

### Explore Outputs
```bash
# View all outputs
terraform output

# View specific output
terraform output instance_info

# View VPC information
terraform output vpc_id
```

---

## Key Concepts Demonstrated

### 1. Module Structure
```
modules/
├── networking/    # Single responsibility: network resources
├── security/      # Single responsibility: security resources
└── compute/       # Single responsibility: compute resources
```

### 2. Module Communication
```hcl
# Networking module outputs VPC ID
output "vpc_id" {
  value = aws_vpc.main.id
}

# Security module uses VPC ID as input
module "security" {
  vpc_id = module.networking.vpc_id
}
```

### 3. Data Flow
```
Root Config → Networking Module → VPC ID → Security Module → SG ID → Compute Module
```

### 4. Reusability
```hcl
# Same module, different configurations
module "dev_networking" {
  source = "./modules/networking"
  project_name = "dev-app"
}

module "prod_networking" {
  source = "./modules/networking"
  project_name = "prod-app"
}
```

---

## Understanding Module Benefits

### Before Modules (Monolithic)
```hcl
# All resources in one file - hard to manage
resource "aws_vpc" "main" { ... }
resource "aws_subnet" "public" { ... }
resource "aws_security_group" "web" { ... }
resource "aws_instance" "web" { ... }
# 50+ lines of mixed resources
```

### After Modules (Organized)
```hcl
# Clean, organized, reusable
module "networking" { ... }
module "security" { ... }
module "compute" { ... }
# 15 lines, easy to understand
```

---

## Cleanup

```bash
# Destroy infrastructure
terraform destroy

# Confirm destruction
terraform state list
```

---

## Next Steps

Now that you understand basic modules:

1. **Modify the modules** - Change instance type, add more ports
2. **Create variations** - Deploy to different regions
3. **Add features** - Include monitoring, backup
4. **Move to advanced** - Ready for the complex parametrized project

---

## Module Design Principles Learned

### 1. Single Responsibility
- Each module has one clear purpose
- Networking handles VPC/subnets only
- Security handles security groups only
- Compute handles EC2 instances only

### 2. Clear Interfaces
- Well-defined inputs (variables)
- Useful outputs for other modules
- Descriptive variable names

### 3. Reusability
- Modules work in different environments
- Parameterized for flexibility
- No hardcoded values

### 4. Composability
- Modules work together seamlessly
- Outputs from one become inputs to another
- Clean data flow

---

## Completion Checklist

- [ ] Project structure created
- [ ] Networking module built and understood
- [ ] Security module built and understood
- [ ] Compute module built and understood
- [ ] Root configuration created
- [ ] Infrastructure deployed successfully
- [ ] Web application accessible
- [ ] Module communication understood
- [ ] Infrastructure cleaned up

---

**Congratulations! You've built your first modular Terraform project!**

*This foundation prepares you for the advanced parametrized infrastructure project next.*