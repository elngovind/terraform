# Terraform Complete Guide: Installation to First Infrastructure
## From Zero to AWS EC2 Instance in 30 Minutes

---

## 📋 **Table of Contents**

1. [Prerequisites](#prerequisites)
2. [Terraform Installation](#terraform-installation)
3. [AWS Setup & Configuration](#aws-setup--configuration)
4. [Create Your First Infrastructure](#create-your-first-infrastructure)
5. [Understanding Terraform Workflow](#understanding-terraform-workflow)
6. [State Management](#state-management)
7. [Cleanup & Best Practices](#cleanup--best-practices)
8. [Troubleshooting](#troubleshooting)
9. [Next Steps](#next-steps)

---

## 🎯 **Prerequisites**

### **Required Tools**
- **Terraform CLI** (1.2.0+)
- **AWS CLI** (latest version)
- **Text Editor** (VS Code, Vim, etc.)
- **Terminal/Command Prompt**

### **Required Accounts**
- **AWS Account** with programmatic access
- **IAM User** with EC2, VPC permissions
- **Credit Card** (for AWS - uses free tier resources)

### **System Requirements**
- **Operating System:** Windows 10+, macOS 10.12+, Linux
- **RAM:** 4GB minimum
- **Disk Space:** 1GB free space
- **Internet Connection:** Required for downloads and AWS API calls

---

## 🚀 **Step 1: Terraform Installation**

### **Option A: Package Managers (Recommended)**

#### **macOS - Homebrew**
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Update Homebrew
brew update

# Install Terraform
brew install terraform

# Verify installation
terraform version
```

#### **Windows - Chocolatey**
```powershell
# Install Chocolatey if not already installed (Run as Administrator)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Terraform
choco install terraform

# Verify installation
terraform version
```

#### **Ubuntu/Debian Linux**
```bash
# Update system and install dependencies
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common

# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

# Add HashiCorp repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update and install Terraform
sudo apt update && sudo apt-get install terraform

# Verify installation
terraform version
```

### **Option B: Manual Installation**

#### **All Operating Systems**
```bash
# Download latest version (check terraform.io/downloads for latest URL)
# For Linux/macOS:
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip

# Extract
unzip terraform_1.6.0_linux_amd64.zip

# Move to PATH (Linux/macOS)
sudo mv terraform /usr/local/bin/

# Make executable
sudo chmod +x /usr/local/bin/terraform

# Verify
terraform version
```

### **Verification**
```bash
# Check version
terraform version

# Expected output:
# Terraform v1.6.0
# on linux_amd64

# Check available commands
terraform -help
```

---

## ☁️ **Step 2: AWS Setup & Configuration**

### **2.1: Create AWS Account**
1. Visit [aws.amazon.com](https://aws.amazon.com)
2. Click "Create an AWS Account"
3. Follow registration process
4. Verify email and phone number
5. Add payment method (free tier available)

### **2.2: Create IAM User**
```bash
# Login to AWS Console
# Navigate to IAM > Users > Add User

# User Details:
# - Username: terraform-user
# - Access type: Programmatic access
# - Permissions: Attach existing policies directly
# - Policy: PowerUserAccess (or EC2FullAccess for minimal setup)
```

### **2.3: Install AWS CLI**

#### **macOS**
```bash
brew install awscli
```

#### **Windows**
```powershell
# Download and install from: https://aws.amazon.com/cli/
# Or use pip:
pip install awscli
```

#### **Linux**
```bash
# Ubuntu/Debian
sudo apt install awscli

# Or using pip
pip3 install awscli
```

### **2.4: Configure AWS Credentials**

#### **Method 1: Environment Variables (Recommended for Learning)**
```bash
# Set environment variables (replace with your actual keys)
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
export AWS_DEFAULT_REGION="us-west-2"

# For Windows PowerShell:
$env:AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
$env:AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
$env:AWS_DEFAULT_REGION="us-west-2"
```

#### **Method 2: AWS CLI Configuration**
```bash
# Configure AWS CLI
aws configure

# Enter when prompted:
# AWS Access Key ID: [Your Access Key]
# AWS Secret Access Key: [Your Secret Key]
# Default region name: us-west-2
# Default output format: json
```

### **2.5: Verify AWS Configuration**
```bash
# Test AWS CLI
aws configure list

# Expected output:
#       Name                    Value             Type    Location
#       ----                    -----             ----    --------
#    profile                <not set>             None    None
# access_key     ****************ZJZK              env    
# secret_key     ****************St8S              env    
#     region                us-west-2              env    

# Test AWS connectivity
aws sts get-caller-identity
```

---

## 🏗️ **Step 3: Create Your First Infrastructure**

### **3.1: Create Project Directory**
```bash
# Create and navigate to project directory
mkdir learn-terraform-aws
cd learn-terraform-aws

# Verify you're in the right directory
pwd
```

### **3.2: Create Terraform Configuration Files**

#### **File 1: terraform.tf (Terraform Configuration)**
```bash
# Create terraform.tf file
cat > terraform.tf << 'EOF'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"
}
EOF
```

#### **File 2: main.tf (Infrastructure Definition)**
```bash
# Create main.tf file
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

### **3.3: Understanding the Configuration**

#### **terraform.tf Block**
- **required_providers:** Specifies which providers to use
- **source:** Where to download the provider from
- **version:** Version constraint for the provider
- **required_version:** Minimum Terraform version required

#### **provider Block**
- **aws:** Configures the AWS provider
- **region:** AWS region where resources will be created

#### **data Block**
- **aws_ami:** Queries AWS for the latest Ubuntu AMI
- **most_recent:** Gets the newest matching AMI
- **filter:** Searches for specific AMI name pattern
- **owners:** Canonical's AWS account ID

#### **resource Block**
- **aws_instance:** Creates an EC2 instance
- **ami:** Uses the AMI ID from the data source
- **instance_type:** t2.micro (free tier eligible)
- **tags:** Metadata for the instance

---

## ⚙️ **Step 4: Terraform Workflow**

### **4.1: Format Configuration**
```bash
# Format Terraform files (optional but recommended)
terraform fmt

# Output shows which files were formatted
# main.tf
```

### **4.2: Initialize Terraform**
```bash
# Initialize Terraform workspace
terraform init

# Expected output:
# Initializing the backend...
# Initializing provider plugins...
# - Finding hashicorp/aws versions matching "~> 5.92"...
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

### **4.3: Validate Configuration**
```bash
# Validate configuration syntax
terraform validate

# Expected output:
# Success! The configuration is valid.
```

### **4.4: Plan Infrastructure Changes**
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

### **4.5: Apply Configuration**
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

### **4.6: Verify Infrastructure Creation**

#### **Using Terraform**
```bash
# List resources in state
terraform state list

# Output:
# data.aws_ami.ubuntu
# aws_instance.app_server

# Show detailed state information
terraform show
```

#### **Using AWS CLI**
```bash
# List EC2 instances
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0]]' --output table

# Expected output:
# |  DescribeInstances  |
# |---------------------|
# |  i-0c636e158c30e48f9|  running  |  learn-terraform  |
```

#### **Using AWS Console**
1. Login to AWS Console
2. Navigate to EC2 Dashboard
3. Click "Instances"
4. Find instance named "learn-terraform"

---

## 📊 **Step 5: Understanding State Management**

### **5.1: Terraform State File**
```bash
# View state file location
ls -la terraform.tfstate

# View state file content (formatted)
terraform show

# View specific resource state
terraform state show aws_instance.app_server
```

### **5.2: State File Structure**
```json
{
  "version": 4,
  "terraform_version": "1.6.0",
  "serial": 1,
  "lineage": "unique-id",
  "outputs": {},
  "resources": [
    {
      "mode": "managed",
      "type": "aws_instance",
      "name": "app_server",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "id": "i-0c636e158c30e48f9",
            "ami": "ami-0026a04369a3093cc",
            "instance_type": "t2.micro"
          }
        }
      ]
    }
  ]
}
```

### **5.3: State Commands**
```bash
# List all resources in state
terraform state list

# Show specific resource
terraform state show aws_instance.app_server

# Pull remote state (if using remote backend)
terraform state pull

# Push local state (if using remote backend)
terraform state push
```

---

## 🧹 **Step 6: Cleanup & Best Practices**

### **6.1: Destroy Infrastructure**
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

### **6.2: Verify Cleanup**
```bash
# Check state file
terraform state list
# (should be empty)

# Check AWS Console or CLI
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0]]' --output table
```

### **6.3: Project Structure Best Practices**
```
learn-terraform-aws/
├── terraform.tf          # Terraform and provider configuration
├── main.tf               # Main infrastructure resources
├── variables.tf          # Input variables (optional)
├── outputs.tf            # Output values (optional)
├── terraform.tfstate     # State file (auto-generated)
├── terraform.tfstate.backup  # State backup (auto-generated)
├── .terraform/           # Provider plugins (auto-generated)
└── .terraform.lock.hcl   # Provider version lock (auto-generated)
```

### **6.4: .gitignore for Terraform**
```bash
# Create .gitignore file
cat > .gitignore << 'EOF'
# Local .terraform directories
**/.terraform/*

# .tfstate files
*.tfstate
*.tfstate.*

# Crash log files
crash.log
crash.*.log

# Exclude all .tfvars files, which are likely to contain sensitive data
*.tfvars
*.tfvars.json

# Ignore override files
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Include override files you do wish to add to version control using negated pattern
# !example_override.tf

# Include tfplan files to ignore the plan output of command: terraform plan -out=tfplan
*tfplan*

# Ignore CLI configuration files
.terraformrc
terraform.rc
EOF
```

---

## 🐛 **Step 7: Troubleshooting**

### **Common Issues and Solutions**

#### **Issue 1: Terraform not found**
```bash
# Error: terraform: command not found

# Solution: Check installation
which terraform
echo $PATH

# Re-install or add to PATH
export PATH=$PATH:/usr/local/bin
```

#### **Issue 2: AWS credentials not configured**
```bash
# Error: No valid credential sources found

# Solution: Set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"

# Or configure AWS CLI
aws configure
```

#### **Issue 3: Permission denied errors**
```bash
# Error: UnauthorizedOperation

# Solution: Check IAM permissions
aws sts get-caller-identity

# Ensure user has EC2 permissions:
# - EC2FullAccess (for learning)
# - PowerUserAccess (broader permissions)
```

#### **Issue 4: Region-specific AMI not found**
```bash
# Error: InvalidAMIID.NotFound

# Solution: Update AMI filter or change region
# Check available AMIs:
aws ec2 describe-images --owners 099720109477 --filters "Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*" --query 'Images[*].[ImageId,Name]' --output table
```

#### **Issue 5: State file locked**
```bash
# Error: Error acquiring the state lock

# Solution: Force unlock (use carefully)
terraform force-unlock LOCK_ID

# Or wait for lock to expire
# Or check if another terraform process is running
```

### **Debug Commands**
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

## 🎯 **Step 8: Next Steps**

### **8.1: Enhance Your Configuration**

#### **Add Variables (variables.tf)**
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

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "learning"
}
```

#### **Add Outputs (outputs.tf)**
```hcl
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.app_server.public_dns
}
```

#### **Update main.tf to use variables**
```hcl
provider "aws" {
  region = var.region
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  tags = {
    Name        = "learn-terraform"
    Environment = var.environment
    Project     = "terraform-tutorial"
  }
}
```

### **8.2: Learning Path**

#### **Beginner Level**
1. ✅ **Complete this tutorial**
2. **Add security groups and key pairs**
3. **Create multiple resources**
4. **Use terraform.tfvars files**
5. **Explore different providers**

#### **Intermediate Level**
1. **Learn about modules**
2. **Implement remote state storage**
3. **Use workspaces**
4. **Implement CI/CD with Terraform**
5. **Learn about data sources**

#### **Advanced Level**
1. **Custom providers**
2. **Terraform Cloud/Enterprise**
3. **Policy as Code (Sentinel)**
4. **Advanced state management**
5. **Multi-cloud deployments**

### **8.3: Useful Resources**

#### **Official Documentation**
- [Terraform Documentation](https://terraform.io/docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Registry](https://registry.terraform.io)

#### **Learning Resources**
- [HashiCorp Learn](https://learn.hashicorp.com/terraform)
- [Terraform Best Practices](https://www.terraform-best-practices.com)
- [AWS Free Tier](https://aws.amazon.com/free)

#### **Community**
- [Terraform Community Forum](https://discuss.hashicorp.com/c/terraform-core)
- [r/Terraform Reddit](https://reddit.com/r/Terraform)
- [Terraform GitHub](https://github.com/hashicorp/terraform)

---

## 📝 **Summary Checklist**

### **Installation & Setup**
- ✅ Terraform installed and verified
- ✅ AWS CLI installed and configured
- ✅ AWS credentials set up
- ✅ IAM user with appropriate permissions

### **First Infrastructure**
- ✅ Project directory created
- ✅ Configuration files written
- ✅ Terraform initialized
- ✅ Configuration validated
- ✅ Infrastructure planned and applied
- ✅ Resources verified in AWS
- ✅ Infrastructure destroyed and cleaned up

### **Understanding Gained**
- ✅ Terraform workflow (init, plan, apply, destroy)
- ✅ HCL syntax and structure
- ✅ Provider configuration
- ✅ Resource definitions
- ✅ Data sources
- ✅ State management basics

### **Next Steps Identified**
- ✅ Variables and outputs
- ✅ Modules and reusability
- ✅ Remote state storage
- ✅ Advanced Terraform features

---

**🎉 Congratulations!** You've successfully completed your first Terraform infrastructure deployment. You now have the foundation to build more complex infrastructure as code solutions.

**Time to Complete:** ~30 minutes  
**Cost:** $0 (using AWS free tier)  
**Skills Gained:** Infrastructure as Code basics, Terraform workflow, AWS integration

---

**Last Updated:** December 2024  
**Terraform Version:** 1.6.x  
**AWS Provider Version:** 5.92.x