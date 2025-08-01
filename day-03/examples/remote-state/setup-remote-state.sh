#!/bin/bash
# Setup script for remote state demo

echo "🚀 Setting up Remote State Demo..."

# Step 1: Create backend infrastructure
echo "Step 1: Creating S3 bucket and DynamoDB table..."
terraform init
terraform apply -auto-approve

# Step 2: Get bucket name
BUCKET_NAME=$(terraform output -raw s3_bucket_name)
echo "✅ Backend created. Bucket name: $BUCKET_NAME"

# Step 3: Update main.tf with actual bucket name
echo "Step 2: Updating backend configuration..."
sed -i.bak "s/terraform-state-demo-12345678/$BUCKET_NAME/g" main.tf
echo "✅ Backend configuration updated"

# Step 4: Rename infrastructure file to main infrastructure
echo "Step 3: Organizing files..."
if [ -f "main-infrastructure.tf" ]; then
    mv main-infrastructure.tf infrastructure.tf
fi

# Step 5: Initialize remote backend
echo "Step 4: Initializing remote backend..."
terraform init -migrate-state -input=false

echo "✅ Remote state setup complete!"
echo "📋 Next steps:"
echo "   1. Run: terraform plan"
echo "   2. Run: terraform apply"
echo "   3. Verify: terraform state list"