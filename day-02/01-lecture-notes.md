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
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt

# Plan deployment
terraform plan

# Apply configuration
terraform apply

# Verify deployment
terraform show
terraform output

# Check AWS console or CLI
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType]' --output table
```

**Problems with this approach:**
- AMI ID is hardcoded (won't work in different regions)
- Instance type is fixed
- Can't easily change for different environments
- No flexibility for scaling or modifications

**Validation Commands:**
```bash
# Test the problems
echo "Testing hardcoded limitations..."

# Try to use in different region (will fail)
terraform plan -var="region=us-west-2"

# Check if AMI exists in different region
aws ec2 describe-images --region us-west-2 --image-ids ami-0c02fb55956c7d316 2>/dev/null || echo "❌ AMI not found in us-west-2"
```

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
# Validate new configuration
terraform validate

# Plan with default values
terraform plan

# Test with different variables
echo "Testing variable flexibility..."

# Test different instance types
terraform plan -var="instance_type=t3.small"
terraform plan -var="instance_type=t2.medium"

# Test different environments
terraform plan -var="environment=staging"
terraform plan -var="environment=prod"

# Test different regions (should work now)
terraform plan -var="region=us-west-2"

# Apply with custom values
terraform apply -var="instance_type=t3.small" -var="instance_name=my-custom-server"

# Verify the changes
terraform output instance_details

# Compare with previous state
terraform show | grep -E "(ami|instance_type|tags)"
```

**Benefits achieved:**
- Dynamic AMI selection (works in any region)
- Configurable instance type
- Flexible naming
- Environment awareness

**Validation Tests:**
```bash
# Test cross-region functionality
echo "Testing cross-region deployment..."
for region in us-east-1 us-west-2 eu-west-1; do
    echo "Testing region: $region"
    terraform plan -var="region=$region" | grep "data.aws_ami.amazon_linux"
done
```

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
# Test validation with invalid values
echo "Testing variable validation..."

# This will fail validation - invalid instance type
echo "Testing invalid instance type:"
terraform plan -var="instance_type=invalid-type" 2>&1 | grep -A3 "Error:"

# This will fail validation - invalid environment
echo "Testing invalid environment:"
terraform plan -var="environment=invalid-env" 2>&1 | grep -A3 "Error:"

# This will fail validation - invalid region format
echo "Testing invalid region:"
terraform plan -var="region=INVALID_REGION" 2>&1 | grep -A3 "Error:"

# This will fail validation - empty instance name
echo "Testing empty instance name:"
terraform plan -var="instance_name=" 2>&1 | grep -A3 "Error:"

# These will pass validation
echo "Testing valid values:"
terraform plan -var="instance_type=t3.small" | grep "Plan:"
terraform plan -var="environment=prod" | grep "Plan:"
terraform plan -var="region=us-west-2" | grep "Plan:"

# Validate configuration syntax
terraform validate
echo "✅ Configuration validation passed"
```

**Advanced Validation Testing:**
```bash
# Create validation test script
cat > test_validation.sh << 'EOF'
#!/bin/bash
echo "=== VARIABLE VALIDATION TESTS ==="

# Test all invalid values
invalid_tests=(
    "instance_type=m5.invalid"
    "environment=testing"
    "region=invalid-region-123"
    "instance_name=$(printf '%*s' 300 | tr ' ' 'a')"  # Too long name
)

for test in "${invalid_tests[@]}"; do
    echo "Testing: $test"
    if terraform plan -var="$test" >/dev/null 2>&1; then
        echo "❌ FAILED: Should have rejected $test"
    else
        echo "✅ PASSED: Correctly rejected $test"
    fi
done
EOF

chmod +x test_validation.sh
./test_validation.sh
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

### Test Complex Data Types
```bash
# Test different data types
echo "Testing complex data types..."

# Test number variable
terraform plan -var="instance_count=3" | grep "3 to add"

# Test boolean variable
terraform plan -var="enable_monitoring=true" | grep "monitoring"

# Test list variable
terraform plan -var='allowed_ports=[80,443,8080]' | grep "ingress"

# Test map variable access
terraform console << 'EOF'
var.instance_types["prod"]
var.instance_types["dev"]
keys(var.instance_types)
EOF

# Test object variable access
terraform console << 'EOF'
var.ec2_config.instance_type
var.ec2_config.storage_size
var.ec2_config.monitoring
EOF

# Validate complex configuration
terraform validate
terraform plan -var="instance_count=2" -var="environment=prod"
```

**Data Type Validation Script:**
```bash
# Create data type testing script
cat > test_data_types.sh << 'EOF'
#!/bin/bash
echo "=== DATA TYPE TESTING ==="

# Test each data type
echo "Testing string type:"
terraform console <<< 'var.instance_name'

echo "Testing number type:"
terraform console <<< 'var.instance_count'

echo "Testing boolean type:"
terraform console <<< 'var.enable_monitoring'

echo "Testing list type:"
terraform console <<< 'var.allowed_ports'
terraform console <<< 'length(var.allowed_ports)'

echo "Testing map type:"
terraform console <<< 'var.instance_types'
terraform console <<< 'keys(var.instance_types)'

echo "Testing object type:"
terraform console <<< 'var.ec2_config'
terraform console <<< 'var.ec2_config.storage_size'
EOF

chmod +x test_data_types.sh
./test_data_types.sh
```
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

### Test Conditional Logic
```bash
# Test environment-specific behavior
echo "Testing conditional logic..."

# Test development environment
echo "=== DEVELOPMENT ENVIRONMENT ==="
terraform plan -var="environment=dev" | grep -E "(Plan:|instance_count|monitoring)"

# Test staging environment
echo "=== STAGING ENVIRONMENT ==="
terraform plan -var="environment=staging" | grep -E "(Plan:|instance_count|monitoring)"

# Test production environment
echo "=== PRODUCTION ENVIRONMENT ==="
terraform plan -var="environment=prod" | grep -E "(Plan:|instance_count|monitoring|alarm|backup)"

# Test conditional expressions in console
terraform console << 'EOF'
# Test environment-specific values
local.env_config["dev"].instance_count
local.env_config["prod"].instance_count

# Test conditional expressions
var.environment == "prod" ? "encrypted" : "not-encrypted"
contains(["staging", "prod"], "prod")
contains(["staging", "prod"], "dev")
EOF
```

**Conditional Logic Testing Script:**
```bash
# Create conditional testing script
cat > test_conditionals.sh << 'EOF'
#!/bin/bash
echo "=== CONDITIONAL LOGIC TESTING ==="

for env in dev staging prod; do
    echo "\n--- Testing $env environment ---"
    
    # Count resources that would be created
    plan_output=$(terraform plan -var="environment=$env" 2>/dev/null)
    
    # Extract plan summary
    echo "$plan_output" | grep "Plan:" || echo "No changes"
    
    # Check for environment-specific resources
    if [[ "$env" == "prod" ]]; then
        echo "Checking for prod-only resources:"
        echo "$plan_output" | grep -q "aws_cloudwatch_metric_alarm" && echo "✅ CloudWatch alarms found" || echo "❌ No CloudWatch alarms"
        echo "$plan_output" | grep -q "encrypted.*true" && echo "✅ Encryption enabled" || echo "❌ No encryption"
    fi
    
    if [[ "$env" == "staging" || "$env" == "prod" ]]; then
        echo "$plan_output" | grep -q "aws_backup_vault" && echo "✅ Backup vault found" || echo "❌ No backup vault"
    fi
done
EOF

chmod +x test_conditionals.sh
./test_conditionals.sh
``` {
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

## Step 6: Looping Concepts - Multiple EC2 Instances (15 minutes)

Learn how to create multiple EC2 instances using count and for_each loops.

### Using Count for Multiple Identical EC2 Instances

```hcl
# Variable for number of instances
variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 2
  
  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

# Create multiple EC2 instances using count
resource "aws_instance" "web" {
  count = var.instance_count
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = local.current_config.instance_type
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  tags = {
    Name        = "${var.instance_name}-${count.index + 1}"
    Environment = var.environment
    Index       = count.index
  }
}
```

### Using for_each for Named EC2 Instances

```hcl
# Variable for named instances
variable "named_instances" {
  description = "Map of named EC2 instances to create"
  type = map(object({
    instance_type = string
    environment   = string
  }))
  default = {
    "web-server" = {
      instance_type = "t2.micro"
      environment   = "dev"
    }
    "api-server" = {
      instance_type = "t2.small"
      environment   = "dev"
    }
  }
}

# Create named EC2 instances using for_each
resource "aws_instance" "named" {
  for_each = var.named_instances
  
  ami           = data.aws_ami.amazon_linux.id
  instance_type = each.value.instance_type
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  tags = {
    Name        = each.key
    Environment = each.value.environment
    Type        = "named-instance"
  }
}
```

### When to Use Count vs for_each

- **Use count when:**
  - Creating identical resources
  - Need simple indexing (0, 1, 2...)
  - Resources are interchangeable

- **Use for_each when:**
  - Creating named resources
  - Each resource has different configuration
  - Need to reference resources by key

---

## Step 7: Region-Specific AMI Selection (15 minutes)

Implement logic to select different AMI IDs based on the deployment region.

### AMI Mapping by Region

```hcl
# Variable for region-specific AMI mapping
variable "region_amis" {
  description = "AMI IDs for different regions"
  type        = map(string)
  default = {
    "us-east-1"      = "ami-0c02fb55956c7d316"  # Amazon Linux 2 in us-east-1
    "us-west-2"      = "ami-0892d3c7ee96c0bf7"  # Amazon Linux 2 in us-west-2
    "eu-west-1"      = "ami-0a8e758f5e873d1c1"  # Amazon Linux 2 in eu-west-1
    "ap-southeast-1" = "ami-0c802847a7dd848c0"  # Amazon Linux 2 in ap-southeast-1
  }
}

# Local value to select AMI based on current region
locals {
  # Get current region
  current_region = data.aws_region.current.name
  
  # Select AMI based on region, fallback to data source if not in map
  selected_ami = lookup(var.region_amis, local.current_region, data.aws_ami.amazon_linux.id)
  
  # Alternative: Use conditional logic for AMI selection
  conditional_ami = (
    local.current_region == "us-east-1" ? "ami-0c02fb55956c7d316" :
    local.current_region == "us-west-2" ? "ami-0892d3c7ee96c0bf7" :
    local.current_region == "eu-west-1" ? "ami-0a8e758f5e873d1c1" :
    data.aws_ami.amazon_linux.id  # fallback to latest
  )
}

# Data source to get current region
data "aws_region" "current" {}

# Data source as fallback for unlisted regions
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# EC2 instance using region-specific AMI
resource "aws_instance" "web" {
  count = var.instance_count
  
  ami           = local.selected_ami
  instance_type = local.current_config.instance_type
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  tags = {
    Name        = "${var.instance_name}-${count.index + 1}"
    Environment = var.environment
    Region      = local.current_region
    AMI         = local.selected_ami
  }
}
```

### Advanced Region-AMI Logic with Validation

```hcl
# More sophisticated region-AMI mapping with OS types
variable "ami_config" {
  description = "AMI configuration by region and OS type"
  type = map(object({
    amazon_linux = string
    ubuntu       = string
    windows      = string
  }))
  default = {
    "us-east-1" = {
      amazon_linux = "ami-0c02fb55956c7d316"
      ubuntu       = "ami-0a634ae95e11c6f91"
      windows      = "ami-0c2a0ede9fd7cb37c"
    }
    "us-west-2" = {
      amazon_linux = "ami-0892d3c7ee96c0bf7"
      ubuntu       = "ami-0a634ae95e11c6f91"
      windows      = "ami-0c2a0ede9fd7cb37c"
    }
  }
}

variable "os_type" {
  description = "Operating system type"
  type        = string
  default     = "amazon_linux"
  
  validation {
    condition     = contains(["amazon_linux", "ubuntu", "windows"], var.os_type)
    error_message = "OS type must be amazon_linux, ubuntu, or windows."
  }
}

# Local logic for AMI selection
locals {
  # Check if current region is supported
  region_supported = contains(keys(var.ami_config), local.current_region)
  
  # Select AMI based on region and OS type
  selected_ami_advanced = (
    local.region_supported ?
    var.ami_config[local.current_region][var.os_type] :
    data.aws_ami.fallback.id
  )
}

# Fallback data source for unsupported regions
data "aws_ami" "fallback" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name = "name"
    values = [
      var.os_type == "amazon_linux" ? "amzn2-ami-hvm-*-x86_64-gp2" :
      var.os_type == "ubuntu" ? "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*" :
      "Windows_Server-2019-English-Full-Base-*"
    ]
  }
}
```

---

## Step 8: Functions and Expressions (10 minutes)

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
  
  # Loop with conditions for instance naming
  instance_names = [for i in range(var.instance_count) : "${var.instance_name}-${format("%02d", i + 1)}"]
}

# Using functions in resource configuration
resource "aws_instance" "web" {
  count = var.instance_count
  
  ami           = local.selected_ami
  instance_type = local.current_config.instance_type
  
  tags = {
    Name         = local.instance_names[count.index]
    Environment  = upper(var.environment)
    DeployedOn   = local.deployment_date
    InstanceNum  = "${count.index + 1} of ${var.instance_count}"
  }
}
```

---

## Step 9: .tfvars Files - Environment-Specific EC2 Deployments (15 minutes)

Create environment-specific configuration files for our EC2 infrastructure.

### dev.tfvars
```hcl
# Development environment configuration
region        = "us-east-1"
environment   = "dev"
instance_name = "dev-web-server"

# Development-specific settings
instance_count   = 2
enable_monitoring = false
allowed_ports    = [80, 22, 8080]  # Extra port for development
os_type          = "amazon_linux"

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

# Named instances for development
named_instances = {
  "dev-web" = {
    instance_type = "t2.micro"
    environment   = "dev"
  }
  "dev-api" = {
    instance_type = "t2.micro"
    environment   = "dev"
  }
}
```

### staging.tfvars
```hcl
# Staging environment configuration
region        = "us-west-2"  # Different region
environment   = "staging"
instance_name = "staging-web-server"

# Staging-specific settings
instance_count   = 3
enable_monitoring = true
allowed_ports    = [80, 443, 22]
os_type          = "ubuntu"

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

# Named instances for staging
named_instances = {
  "staging-web-01" = {
    instance_type = "t2.small"
    environment   = "staging"
  }
  "staging-web-02" = {
    instance_type = "t2.small"
    environment   = "staging"
  }
  "staging-api" = {
    instance_type = "t2.medium"
    environment   = "staging"
  }
}
```

### prod.tfvars
```hcl
# Production environment configuration
region        = "eu-west-1"  # Different region for prod
environment   = "prod"
instance_name = "prod-web-server"

# Production-specific settings
instance_count   = 5
enable_monitoring = true
allowed_ports    = [80, 443]  # Only necessary ports
os_type          = "amazon_linux"

# Production EC2 configuration
ec2_config = {
  instance_type   = "t3.large"
  monitoring      = true
  backup_required = true
  storage_size    = 50
}

instance_types = {
  dev     = "t2.micro"
  staging = "t2.small"
  prod    = "t3.large"
}

# Named instances for production
named_instances = {
  "prod-web-01" = {
    instance_type = "t3.large"
    environment   = "prod"
  }
  "prod-web-02" = {
    instance_type = "t3.large"
    environment   = "prod"
  }
  "prod-api-01" = {
    instance_type = "t3.xlarge"
    environment   = "prod"
  }
  "prod-api-02" = {
    instance_type = "t3.xlarge"
    environment   = "prod"
  }
}
```

---

## Step 10: Terraform Console - Testing EC2 Expressions (10 minutes)

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

# Test region-specific AMI selection
> lookup(var.region_amis, "us-east-1", "default-ami")
"ami-0c02fb55956c7d316"

# Test looping with range
> [for i in range(3) : "instance-${i + 1}"]
[
  "instance-1",
  "instance-2",
  "instance-3"
]

# Test for_each keys
> keys(var.named_instances)
[
  "api-server",
  "web-server"
]
```

---

## Step 11: Deployment with Different Configurations (10 minutes)

Deploy the same EC2 infrastructure with different configurations.

### Deploy Development Environment
```bash
# Validate configuration first
terraform validate

# Plan development deployment
echo "Planning development environment..."
terraform plan -var-file="dev.tfvars"

# Apply development configuration
echo "Applying development environment..."
terraform apply -var-file="dev.tfvars"

# Check outputs
echo "Development environment outputs:"
terraform output

# Verify deployment
echo "Verifying deployment:"
terraform state list
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,Tags[?Key==`Environment`].Value|[0]]' --output table
```

### Deploy Staging Environment
```bash
# Switch to staging workspace (optional)
terraform workspace new staging
terraform workspace select staging

# Plan staging deployment
echo "Planning staging environment..."
terraform plan -var-file="staging.tfvars"

# Show differences from dev
echo "Comparing staging vs dev:"
terraform plan -var-file="staging.tfvars" | grep -E "(Plan:|instance_type|region)"

# Apply staging configuration
echo "Applying staging environment..."
terraform apply -var-file="staging.tfvars"

# Verify staging deployment
echo "Staging environment verification:"
terraform output
terraform state list | wc -l
```

### Compare Environments
```bash
# Create environment comparison script
cat > compare_all_environments.sh << 'EOF'
#!/bin/bash
echo "=== ENVIRONMENT COMPARISON ==="

for env in dev staging prod; do
    echo "\n--- $env Environment ---"
    plan_output=$(terraform plan -var-file="${env}.tfvars" 2>/dev/null)
    
    # Extract key information
    echo "$plan_output" | grep "Plan:" || echo "No changes"
    
    # Show resource counts
    instance_count=$(echo "$plan_output" | grep -c "aws_instance.web\[")
    echo "EC2 Instances: $instance_count"
    
    # Show instance types
    echo "$plan_output" | grep "instance_type" | head -1
    
    # Show region
    echo "$plan_output" | grep "region" | head -1
    
    # Check for conditional resources
    if echo "$plan_output" | grep -q "aws_cloudwatch_metric_alarm"; then
        echo "✅ Monitoring enabled"
    else
        echo "❌ No monitoring"
    fi
    
    if echo "$plan_output" | grep -q "aws_backup_vault"; then
        echo "✅ Backup enabled"
    else
        echo "❌ No backup"
    fi
done
EOF

chmod +x compare_all_environments.sh
./compare_all_environments.sh

# Compare what would be different in production
echo "\nDetailed production comparison:"
terraform plan -var-file="prod.tfvars"

# Notice the differences:
# - Different region (eu-west-1 vs us-east-1)
# - Different AMI (region-specific)
# - More instances (5 vs 2)
# - Larger instance types (t3.large vs t2.micro)
# - Different OS type (varies by environment)
# - Named instances with different configurations
# - Additional monitoring and backup
```

---

## Step 12: Variable Precedence Testing (10 minutes)

Understand how Terraform resolves variable values.

### Variable Precedence Order (highest to lowest)
1. Command line `-var` flags
2. Command line `-var-file` flags
3. Environment variables (`TF_VAR_name`)
4. `terraform.tfvars` or `*.auto.tfvars`
5. Default values in `variables.tf`

### Testing Precedence
```bash
# Create precedence testing script
cat > test_precedence.sh << 'EOF'
#!/bin/bash
echo "=== VARIABLE PRECEDENCE TESTING ==="

# Test 1: Default value (lowest precedence)
echo "\n1. Testing default value:"
terraform console <<< 'var.instance_type'

# Test 2: tfvars file
echo "\n2. Testing tfvars file value:"
terraform plan -var-file="dev.tfvars" | grep "instance_type" | head -1

# Test 3: Environment variable
echo "\n3. Testing environment variable:"
export TF_VAR_instance_type="t3.small"
terraform console <<< 'var.instance_type'
echo "Environment variable set to: $TF_VAR_instance_type"

# Test 4: Command line (highest precedence)
echo "\n4. Testing command line override:"
terraform plan -var="instance_type=t2.medium" | grep "instance_type" | head -1

# Test 5: Multiple sources
echo "\n5. Testing multiple sources (CLI should win):"
terraform plan -var-file="dev.tfvars" -var="instance_type=t3.large" | grep "instance_type" | head -1

# Cleanup
unset TF_VAR_instance_type
echo "\nPrecedence testing completed."
EOF

chmod +x test_precedence.sh
./test_precedence.sh

# Manual testing
echo "\nManual precedence testing:"

# Set environment variable
export TF_VAR_instance_type="t3.small"
echo "Environment variable set to: $TF_VAR_instance_type"

# This will use t3.small from environment variable
echo "Testing environment variable precedence:"
terraform plan -var-file="dev.tfvars" | grep "instance_type" | head -1

# This will override with t2.medium from command line
echo "Testing command line override:"
terraform plan -var-file="dev.tfvars" -var="instance_type=t2.medium" | grep "instance_type" | head -1

# Clean up environment variable
unset TF_VAR_instance_type
echo "Environment variable cleared."
```

---

## Key Concepts Summary

### Evolution of Our EC2 Configuration

1. **Hardcoded** → Fixed AMI, instance type, region
2. **Variables** → Flexible configuration with defaults
3. **Validation** → Safe input values
4. **Data Types** → Complex configurations (lists, maps, objects)
5. **Conditionals** → Environment-specific behavior
6. **Looping** → Multiple instances with count and for_each
7. **Region-AMI Logic** → Dynamic AMI selection based on region
8. **Functions** → Dynamic value computation
9. **.tfvars** → Environment separation
10. **Console** → Expression testing
11. **Precedence** → Variable resolution understanding

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
# Create cleanup script for all environments
cat > cleanup_all.sh << 'EOF'
#!/bin/bash
echo "=== CLEANING UP ALL ENVIRONMENTS ==="

# Cleanup development
echo "\nCleaning up development environment..."
terraform workspace select default
terraform destroy -var-file="dev.tfvars" -auto-approve

# Cleanup staging
if terraform workspace list | grep -q staging; then
    echo "\nCleaning up staging environment..."
    terraform workspace select staging
    terraform destroy -var-file="staging.tfvars" -auto-approve
    terraform workspace select default
    terraform workspace delete staging
fi

# Verify cleanup
echo "\nVerifying cleanup..."
terraform state list || echo "No resources in state"
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table | grep -v terminated || echo "No running instances"

echo "\nCleanup completed!"
EOF

chmod +x cleanup_all.sh
./cleanup_all.sh

# Manual cleanup commands
echo "Manual cleanup commands:"

# Destroy development environment
echo "Destroying development environment..."
terraform destroy -var-file="dev.tfvars"

# Switch to staging and destroy
if terraform workspace list | grep -q staging; then
    echo "Destroying staging environment..."
    terraform workspace select staging
    terraform destroy -var-file="staging.tfvars"
    terraform workspace select default
    terraform workspace delete staging
fi

# Final verification
echo "Final verification:"
terraform state list
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table
```

---

**You've successfully transformed a simple, hardcoded EC2 instance into a flexible, parameterized, production-ready infrastructure configuration!**

This progression from hardcoded to parameterized infrastructure demonstrates the power of Terraform's variable system and prepares you for building complex, reusable infrastructure as code.