# Day 1 Hands-On Lab: Your First Terraform Infrastructure
## From Zero to AWS EC2 Instance

**Duration:** 60 minutes | **Prerequisites:** Terraform and AWS CLI installed

---

## Lab Overview

In this hands-on lab, you will:
1. Create your first Terraform configuration
2. Deploy an EC2 instance on AWS
3. Understand the Terraform workflow
4. Learn about state management
5. Clean up resources properly

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Project Setup](#project-setup)
3. [Create Configuration Files](#create-configuration-files)
4. [Terraform Workflow](#terraform-workflow)
5. [Understanding State](#understanding-state)
6. [Cleanup](#cleanup)
7. [Troubleshooting](#troubleshooting)
8. [Next Steps](#next-steps)

---

## Prerequisites

### Required Tools
- **Terraform CLI** (1.2.0+)
- **AWS CLI** (latest version)
- **Text Editor** (VS Code, Vim, etc.)
- **Terminal/Command Prompt**

### Required Accounts
- **AWS Account** with programmatic access
- **IAM User** with EC2, VPC permissions

### AWS Configuration
Ensure your AWS credentials are configured:

```bash
# Method 1: Environment Variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"

# Method 2: AWS CLI
aws configure

# Verify configuration
aws sts get-caller-identity
```

---

## Project Setup

### Create Project Directory
```bash
# Create and navigate to project directory
mkdir learn-terraform-aws
cd learn-terraform-aws

# Verify you're in the right directory
pwd
```

---

## Create Configuration Files

### File 1: versions.tf (Provider Configuration)
```bash
cat > versions.tf << 'EOF'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.2"
}
EOF
```

### File 2: main.tf (Infrastructure Definition)
```bash
cat > main.tf << 'EOF'
# Configure the AWS Provider
provider "aws" {
  region = "us-west-2"
}

# Data source to get the latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

# Create EC2 instance
resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  tags = {
    Name        = "learn-terraform"
    Environment = "learning"
    Project     = "terraform-tutorial"
  }
}
EOF
```

### Understanding the Configuration

**versions.tf Block:**
- **required_providers:** Specifies which providers to use
- **source:** Where to download the provider from
- **version:** Version constraint for the provider
- **required_version:** Minimum Terraform version required

**provider Block:**
- **aws:** Configures the AWS provider
- **region:** AWS region where resources will be created

**data Block:**
- **aws_ami:** Queries AWS for the latest Ubuntu AMI
- **most_recent:** Gets the newest matching AMI
- **filter:** Searches for specific AMI name pattern
- **owners:** Canonical's AWS account ID

**resource Block:**
- **aws_instance:** Creates an EC2 instance
- **ami:** Uses the AMI ID from the data source
- **instance_type:** t2.micro (free tier eligible)
- **tags:** Metadata for the instance

---

## Terraform Workflow

### Step 1: Format Configuration
```bash
# Format Terraform files (optional but recommended)
terraform fmt

# Output shows which files were formatted
```

### Step 2: Initialize Terraform
```bash
# Initialize Terraform workspace
terraform init

# Expected output:
# Initializing the backend...
# Initializing provider plugins...
# - Finding hashicorp/aws versions matching "~> 5.0"...
# - Installing hashicorp/aws v5.98.0...
# - Installed hashicorp/aws v5.98.0 (signed by HashiCorp)
# 
# Terraform has been successfully initialized!
```

**What happens during init:**
- Downloads and installs providers
- Creates `.terraform` directory
- Creates `.terraform.lock.hcl` file
- Prepares backend for state storage

### Step 3: Validate Configuration
```bash
# Validate configuration syntax
terraform validate

# Expected output:
# Success! The configuration is valid.
```

### Step 4: Plan Infrastructure Changes
```bash
# Create execution plan
terraform plan

# Expected output:
# data.aws_ami.ubuntu: Reading...
# data.aws_ami.ubuntu: Read complete after 1s [id=ami-0026a04369a3093cc]
# 
# Terraform used the selected providers to generate the following execution plan.
# Resource actions are indicated with the following symbols:
#   + create
# 
# Terraform will perform the following actions:
# 
#   # aws_instance.app_server will be created
#   + resource "aws_instance" "app_server" {
#       + ami                                  = "ami-0026a04369a3093cc"
#       + instance_type                        = "t2.micro"
#       + tags                                 = {
#           + "Environment" = "learning"
#           + "Name"        = "learn-terraform"
#           + "Project"     = "terraform-tutorial"
#         }
#       # ... (many more attributes shown)
#     }
# 
# Plan: 1 to add, 0 to change, 0 to destroy.
```

**Understanding the Plan:**
- **+** means resource will be created
- **~** means resource will be modified
- **-** means resource will be destroyed
- **(known after apply)** means value determined during creation

### Step 5: Apply Configuration
```bash
# Apply the configuration
terraform apply

# Review the plan and type 'yes' when prompted
# Do you want to perform these actions?
#   Terraform will perform the actions described above.
#   Only 'yes' will be accepted to approve.
# 
#   Enter a value: yes

# Expected output:
# aws_instance.app_server: Creating...
# aws_instance.app_server: Still creating... [10s elapsed]
# aws_instance.app_server: Creation complete after 14s [id=i-0c636e158c30e48f9]
# 
# Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

### Step 6: Verify Infrastructure Creation

**Using Terraform:**
```bash
# List resources in state
terraform state list

# Output:
# data.aws_ami.ubuntu
# aws_instance.app_server

# Show detailed state information
terraform show
```

**Using AWS CLI:**
```bash
# List EC2 instances
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0]]' --output table

# Expected output:
# |  DescribeInstances  |
# |---------------------|
# |  i-0c636e158c30e48f9|  running  |  learn-terraform  |
```

**Using AWS Console:**
1. Login to AWS Console
2. Navigate to EC2 Dashboard
3. Click "Instances"
4. Find instance named "learn-terraform"

---

## Understanding State

### Terraform State File
```bash
# View state file location
ls -la terraform.tfstate

# View state file content (formatted)
terraform show

# View specific resource state
terraform state show aws_instance.app_server
```

### State File Structure
The state file contains:
- **version:** State file format version
- **terraform_version:** Terraform version used
- **serial:** State file serial number
- **lineage:** Unique identifier for state
- **resources:** All managed resources and their attributes

### State Commands
```bash
# List all resources in state
terraform state list

# Show specific resource
terraform state show aws_instance.app_server

# Pull remote state (if using remote backend)
terraform state pull

# Refresh state from real infrastructure
terraform refresh
```

---

## Cleanup

### Destroy Infrastructure
```bash
# Plan destruction
terraform plan -destroy

# Destroy infrastructure
terraform destroy

# Type 'yes' when prompted
# Expected output:
# aws_instance.app_server: Destroying... [id=i-0c636e158c30e48f9]
# aws_instance.app_server: Still destroying... [id=i-0c636e158c30e48f9, 10s elapsed]
# aws_instance.app_server: Destruction complete after 31s
# 
# Destroy complete! Resources: 1 destroyed.
```

### Verify Cleanup
```bash
# Check state file
terraform state list
# (should be empty)

# Check AWS Console or CLI
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0]]' --output table
```

### Project Structure
```
learn-terraform-aws/
├── versions.tf              # Terraform and provider configuration
├── main.tf                  # Main infrastructure resources
├── terraform.tfstate        # State file (auto-generated)
├── terraform.tfstate.backup # State backup (auto-generated)
├── .terraform/              # Provider plugins (auto-generated)
└── .terraform.lock.hcl      # Provider version lock (auto-generated)
```

---

## Troubleshooting

### Common Issues and Solutions

**Issue 1: Terraform not found**
```bash
# Error: terraform: command not found

# Solution: Check installation
which terraform
echo $PATH

# Re-install or add to PATH
export PATH=$PATH:/usr/local/bin
```

**Issue 2: AWS credentials not configured**
```bash
# Error: No valid credential sources found

# Solution: Set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"

# Or configure AWS CLI
aws configure
```

**Issue 3: Permission denied errors**
```bash
# Error: UnauthorizedOperation

# Solution: Check IAM permissions
aws sts get-caller-identity

# Ensure user has EC2 permissions:
# - EC2FullAccess (for learning)
# - PowerUserAccess (broader permissions)
```

**Issue 4: Region-specific AMI not found**
```bash
# Error: InvalidAMIID.NotFound

# Solution: Update AMI filter or change region
# Check available AMIs:
aws ec2 describe-images --owners 099720109477 --filters "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" --query 'Images[*].[ImageId,Name]' --output table
```

### Debug Commands
```bash
# Enable debug logging
export TF_LOG=DEBUG
terraform plan

# Disable debug logging
unset TF_LOG

# Validate configuration
terraform validate

# Check formatting
terraform fmt -check

# Refresh state
terraform refresh
```

---

## Next Steps

### Enhance Your Configuration

**Add Variables (variables.tf):**
```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}
```

**Add Outputs (outputs.tf):**
```hcl
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}
```

### Learning Path
1. Complete the [Day 1 Assessment](04-assessment.md)
2. Work on the [Day 1 Assignment](../assignments/day-01-assignment.md)
3. Prepare for [Day 2: Modular Architecture](../day-02/)

---

## Lab Completion Checklist

- [ ] Project directory created
- [ ] Configuration files written
- [ ] Terraform initialized successfully
- [ ] Configuration validated
- [ ] Infrastructure planned and applied
- [ ] EC2 instance verified in AWS
- [ ] State file understood
- [ ] Infrastructure destroyed and cleaned up
- [ ] Troubleshooting techniques learned

---

**Congratulations! You've successfully deployed your first infrastructure with Terraform!**

*Time to Complete: ~60 minutes*  
*Cost: $0 (using AWS free tier)*  
*Skills Gained: Terraform workflow, HCL syntax, AWS integration*