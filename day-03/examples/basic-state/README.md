# Basic State Example

This example demonstrates Terraform state management with a simple EC2 instance using **local state**.

## 🎯 Learning Objectives
- Understand local state file creation
- Observe state file structure
- Practice basic state commands

## 📁 Files
- `main.tf` - Main configuration with EC2 instance and security group
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `terraform.tfstate` - State file (created after apply)

## 🚀 Step-by-Step Execution

### Step 1: Initialize Terraform
```bash
terraform init
```
**What happens:**
- Downloads AWS provider
- Creates `.terraform` directory
- No remote backend configured (uses local state)

### Step 2: Plan Infrastructure
```bash
terraform plan
```
**What happens:**
- Terraform reads configuration
- No state file exists yet
- Shows resources to be created

### Step 3: Apply Configuration
```bash
terraform apply
```
**What happens:**
- Creates AWS resources
- **Creates `terraform.tfstate` file**
- State file contains resource mappings

### Step 4: Examine State File
```bash
# View state file structure
cat terraform.tfstate | jq '.'

# List resources in state
terraform state list

# Show specific resource details
terraform state show aws_instance.web
```

### Step 5: Observe State Contents
```bash
# Check state file metadata
cat terraform.tfstate | jq '{version, terraform_version, serial, lineage}'

# View resource details
cat terraform.tfstate | jq '.resources[0]'
```

## 🔍 State File Analysis

### State File Structure
```json
{
  "version": 4,
  "terraform_version": "1.6.0",
  "serial": 1,
  "lineage": "unique-uuid-here",
  "outputs": {
    "instance_id": {
      "value": "i-1234567890abcdef0",
      "type": "string"
    }
  },
  "resources": [
    {
      "mode": "managed",
      "type": "aws_instance",
      "name": "web",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "id": "i-1234567890abcdef0",
            "ami": "ami-12345678",
            "instance_type": "t2.micro",
            "public_ip": "54.123.45.67"
          }
        }
      ]
    }
  ]
}
```

## 🧪 State Experiments

### Experiment 1: State Inspection
```bash
# List all resources
terraform state list

# Expected output:
# aws_instance.web
# aws_security_group.web_sg

# Show instance details
terraform state show aws_instance.web
```

### Experiment 2: State Modification
```bash
# Remove resource from state (keeps AWS resource)
terraform state rm aws_security_group.web_sg

# Verify removal
terraform state list

# Check what Terraform wants to do
terraform plan
# Should show security group as "to be created"

# Re-import the security group
terraform import aws_security_group.web_sg sg-xxxxxxxxx
```

### Experiment 3: State Backup and Restore
```bash
# Create backup
cp terraform.tfstate terraform.tfstate.backup

# Simulate corruption (don't do this in production!)
echo '{}' > terraform.tfstate

# Try to plan (will fail)
terraform plan

# Restore from backup
cp terraform.tfstate.backup terraform.tfstate

# Verify restoration
terraform plan
```

## 📊 Key Observations

### Local State Characteristics:
1. **File Location**: `terraform.tfstate` in current directory
2. **Format**: JSON with resource mappings
3. **Metadata**: Version, serial number, lineage
4. **Security**: No encryption, accessible to anyone with file access
5. **Collaboration**: Not suitable for teams

### State File Contents:
- **Resources**: All managed resources with attributes
- **Outputs**: Computed output values
- **Dependencies**: Resource dependency information
- **Provider Info**: Provider versions and configurations

## ⚠️ Important Notes

1. **Never edit state file manually** - Use terraform commands
2. **State contains sensitive data** - Secure appropriately
3. **Local state limitations**:
   - No team collaboration
   - No locking mechanism
   - Risk of data loss
   - No encryption

## 🧹 Cleanup
```bash
# Destroy resources
terraform destroy

# Verify state file is updated
cat terraform.tfstate | jq '.resources'
# Should be empty array

# Remove state file
rm terraform.tfstate*
```

## 🎯 Next Steps
- Move to remote state example
- Learn state operations
- Practice with VPC/EC2 demo