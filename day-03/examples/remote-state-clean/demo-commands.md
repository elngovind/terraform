# Remote State Demo - Copy-Paste Commands

## Phase 1: Create Backend Infrastructure

```bash
# Navigate to demo directory
cd day-03/examples/remote-state-clean

# Copy backend setup
cp 01-backend-setup.tf main.tf

# Initialize and create S3 bucket + DynamoDB table
terraform init
terraform apply

# Get bucket name for next step
BUCKET_NAME=$(terraform output -raw s3_bucket_name)
echo "Bucket name: $BUCKET_NAME"
```

## Phase 2: Configure Remote Backend

```bash
# Clean up local state
rm main.tf terraform.tfstate*

# Copy infrastructure configuration
cp 02-main-infrastructure.tf main.tf

# Update with actual bucket name
sed -i "s/terraform-state-demo-XXXXXXXX/$BUCKET_NAME/g" main.tf

# Verify the update
grep "bucket.*=" main.tf
```

## Phase 3: Deploy with Remote State

```bash
# Initialize with remote backend
terraform init

# Deploy infrastructure
terraform plan
terraform apply

# Verify remote state
terraform state list
```

## Phase 4: Demonstrate State Operations

```bash
# Check no local state exists
ls -la terraform.tfstate*

# Pull remote state for examination
terraform state pull > remote-state-backup.json
cat remote-state-backup.json | jq '.resources | length'

# Show specific resource
terraform state show aws_instance.demo

# Verify S3 storage
aws s3 ls s3://$BUCKET_NAME/demo/
```

## Phase 5: State Manipulation Demo

```bash
# Remove security group from state
terraform state rm aws_security_group.demo

# Check what Terraform wants to recreate
terraform plan

# Get security group ID and re-import
SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=remote-state-demo-*" --query 'SecurityGroups[0].GroupId' --output text)
terraform import aws_security_group.demo $SG_ID

# Verify import
terraform plan
```

## Phase 6: State Locking Demo

```bash
# Terminal 1: Start a long operation
terraform apply &

# Terminal 2: Try another operation (should be blocked)
terraform plan
# Should show: Error acquiring the state lock

# Check DynamoDB for lock
aws dynamodb scan --table-name terraform-state-locks
```

## Cleanup Commands

```bash
# Destroy infrastructure
terraform destroy

# Switch back to backend setup to destroy backend (optional)
rm main.tf
cp 01-backend-setup.tf main.tf
terraform init
terraform destroy

# Clean up files
rm -f terraform.tfstate* *.json
```

## Verification Commands

```bash
# Verify no AWS resources remain
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=remote-state-demo-vpc"
aws s3 ls | grep terraform-state-demo
aws dynamodb list-tables | grep terraform-state-locks
```