# Clean Remote State Demonstration

This is a simplified, working remote state example with clear separation of concerns.

## 🎯 Objective
Demonstrate remote state management with S3 backend and DynamoDB locking.

## 📁 Files
- `01-backend-setup.tf` - Creates S3 bucket and DynamoDB table
- `02-main-infrastructure.tf` - Infrastructure with remote backend
- `demo-commands.md` - Step-by-step commands

## 🚀 Step-by-Step Process

### Step 1: Create Backend Infrastructure
```bash
# Use the backend setup file
cp 01-backend-setup.tf main.tf

# Initialize and create backend
terraform init
terraform apply

# Note the bucket name from output
terraform output s3_bucket_name
```

### Step 2: Switch to Remote Backend
```bash
# Clean up local state
rm main.tf terraform.tfstate*

# Use the infrastructure file
cp 02-main-infrastructure.tf main.tf

# Update bucket name in main.tf (line 7)
BUCKET_NAME=$(terraform output -raw s3_bucket_name)
sed -i "s/terraform-state-demo-XXXXXXXX/$BUCKET_NAME/g" main.tf

# Initialize with remote backend
terraform init

# Deploy infrastructure
terraform apply
```

### Step 3: Verify Remote State
```bash
# Check no local state exists
ls -la terraform.tfstate*

# List resources from remote state
terraform state list

# Pull remote state
terraform state pull > remote-state.json
cat remote-state.json | jq '.resources | length'

# Verify S3 storage
aws s3 ls s3://$BUCKET_NAME/demo/
```

## 🔍 State Operations Demo

### State Inspection
```bash
terraform state list
terraform state show aws_instance.demo
terraform show
```

### State Manipulation
```bash
# Remove from state (keeps AWS resource)
terraform state rm aws_security_group.demo

# Check what Terraform wants to do
terraform plan

# Re-import
SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=remote-state-demo-*" --query 'SecurityGroups[0].GroupId' --output text)
terraform import aws_security_group.demo $SG_ID
```

### State Locking Demo
```bash
# Terminal 1: Start long operation
terraform apply &

# Terminal 2: Try another operation (will be blocked)
terraform plan
```

## 🧹 Cleanup
```bash
# Destroy infrastructure
terraform destroy

# Switch back to backend setup
rm main.tf
cp 01-backend-setup.tf main.tf

# Destroy backend (optional)
terraform destroy
```

## ✅ Key Benefits Demonstrated
- Remote state storage in S3
- State locking with DynamoDB
- Team collaboration capability
- State encryption and versioning
- No local state files