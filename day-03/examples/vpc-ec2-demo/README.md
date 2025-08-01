# VPC/EC2 Complete Infrastructure Demo

This example demonstrates advanced Terraform state management with a **complete, production-ready infrastructure** including VPC, subnets, load balancer, auto scaling, and optional RDS database.

## 🏗️ Architecture Overview

```
Internet Gateway
       |
   Public Subnets (Multi-AZ)
       |
Application Load Balancer
       |
Auto Scaling Group (EC2 Instances)
       |
   Private Subnets (Multi-AZ)
       |
   RDS Database (Optional)
```

## 🎯 Learning Objectives
- Manage complex infrastructure state
- Understand resource dependencies in state
- Practice advanced state operations
- Observe state with multiple resource types
- Learn state management at scale

## 📁 Infrastructure Components

### Networking
- **VPC** with custom CIDR block
- **Public Subnets** (2) across multiple AZs
- **Private Subnets** (2) across multiple AZs
- **Internet Gateway** for public internet access
- **NAT Gateways** for private subnet internet access
- **Route Tables** with proper routing

### Compute
- **Launch Template** with user data script
- **Auto Scaling Group** with configurable capacity
- **Application Load Balancer** with health checks
- **Target Group** for load balancer routing
- **Security Groups** with least privilege access

### Database (Optional)
- **RDS MySQL** instance in private subnets
- **DB Subnet Group** for multi-AZ deployment
- **Database Security Group** with restricted access

## 🚀 Deployment Instructions

### Prerequisites
1. **Backend Setup**: Complete the remote-state example first
2. **AWS Credentials**: Ensure AWS CLI is configured
3. **Terraform**: Version 1.0 or higher

### Step 1: Configure Backend
Update the backend configuration in `main.tf`:
```hcl
terraform {
  backend "s3" {
    bucket         = "your-actual-bucket-name"  # Update this!
    key            = "vpc-ec2-demo/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}
```

### Step 2: Review Variables
Check `variables.tf` and create `terraform.tfvars` if needed:
```hcl
# terraform.tfvars (optional)
project_name = "my-terraform-demo"
environment = "dev"
vpc_cidr = "10.0.0.0/16"
instance_type = "t2.micro"
asg_desired_capacity = 2
create_database = false  # Set to true if you want RDS
```

### Step 3: Initialize and Deploy
```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy infrastructure
terraform apply
```

### Step 4: Verify Deployment
```bash
# Check outputs
terraform output

# Access the web application
terraform output web_url
# Visit the URL in your browser
```

## 🔍 State Management Demonstrations

### 1. State Structure Analysis
```bash
# List all resources in state
terraform state list

# Expected output (partial):
# aws_vpc.main
# aws_subnet.public[0]
# aws_subnet.public[1]
# aws_subnet.private[0]
# aws_subnet.private[1]
# aws_internet_gateway.main
# aws_nat_gateway.main[0]
# aws_nat_gateway.main[1]
# aws_lb.web
# aws_autoscaling_group.web
# ... and more

# Count resources by type
terraform state list | cut -d. -f1 | sort | uniq -c
```

### 2. Resource Dependencies
```bash
# Show specific resource with dependencies
terraform state show aws_autoscaling_group.web

# View dependency graph
terraform graph | dot -Tpng > infrastructure-graph.png

# Analyze dependencies in JSON format
terraform show -json | jq '.values.root_module.resources[] | select(.address=="aws_autoscaling_group.web") | .depends_on'
```

### 3. State Operations on Complex Infrastructure
```bash
# Remove a route table association from state
terraform state rm 'aws_route_table_association.public[0]'

# Check what Terraform wants to recreate
terraform plan

# Re-import the association
SUBNET_ID=$(terraform output -json public_subnet_ids | jq -r '.[0]')
RT_ID=$(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=*public-rt" --query 'RouteTables[0].RouteTableId' --output text)
terraform import 'aws_route_table_association.public[0]' "$SUBNET_ID/$RT_ID"
```

### 4. State Backup for Complex Infrastructure
```bash
# Create comprehensive backup
terraform state pull > vpc-ec2-state-backup-$(date +%Y%m%d-%H%M%S).json

# Analyze backup size and complexity
ls -lh vpc-ec2-state-backup-*.json
cat vpc-ec2-state-backup-*.json | jq '.resources | length'
```

## 🧪 Advanced State Experiments

### Experiment 1: Resource Count Changes
```bash
# Increase public subnet count
# Edit terraform.tfvars: public_subnet_count = 3
terraform plan
terraform apply

# Observe state changes
terraform state list | grep public
```

### Experiment 2: Auto Scaling Group State
```bash
# Show ASG state details
terraform state show aws_autoscaling_group.web

# Scale the ASG manually via AWS Console
aws autoscaling set-desired-capacity --auto-scaling-group-name $(terraform output -raw autoscaling_group_name) --desired-capacity 3

# Detect drift
terraform plan -detailed-exitcode

# Refresh state to match reality
terraform apply -refresh-only
```

### Experiment 3: Load Balancer Target Health
```bash
# Check target group health
aws elbv2 describe-target-health --target-group-arn $(terraform output -raw target_group_arn)

# Show load balancer in state
terraform state show aws_lb.web
```

## 📊 State File Analysis

### Resource Relationships
The state file shows complex relationships:
- **VPC** → **Subnets** → **Route Tables** → **Associations**
- **Launch Template** → **Auto Scaling Group** → **Target Group** → **Load Balancer**
- **Security Groups** → **EC2 Instances** → **Database**

### State File Size
```bash
# Check state file size
terraform state pull | wc -c

# Analyze resource distribution
terraform state pull | jq '.resources | group_by(.type) | map({type: .[0].type, count: length}) | sort_by(.count) | reverse'
```

## 🛡️ Security Considerations

### State Security
- State contains sensitive information (database passwords)
- S3 encryption protects state at rest
- IAM policies control state access
- DynamoDB locking prevents concurrent modifications

### Infrastructure Security
- Security groups follow least privilege principle
- Database in private subnets only
- NAT gateways for private subnet internet access
- Load balancer handles public traffic

## 🔧 Troubleshooting Common Issues

### Issue 1: Auto Scaling Group Updates
```bash
# If ASG instances don't update after launch template changes
terraform apply -replace=aws_autoscaling_group.web
```

### Issue 2: Load Balancer Health Checks
```bash
# Check target group health
aws elbv2 describe-target-health --target-group-arn $(terraform output -raw target_group_arn)

# View load balancer logs (if enabled)
aws logs describe-log-groups --log-group-name-prefix "/aws/applicationloadbalancer/"
```

### Issue 3: NAT Gateway Connectivity
```bash
# Test private subnet connectivity
# SSH to instance in private subnet and test internet access
curl -I http://www.google.com
```

## 📈 Scaling Considerations

### Horizontal Scaling
- Increase `asg_desired_capacity` for more instances
- Add more availability zones with additional subnets
- Scale database with read replicas

### Vertical Scaling
- Change `instance_type` for more powerful instances
- Upgrade `db_instance_class` for better database performance

## 🧹 Cleanup Process

### Step 1: Destroy Infrastructure
```bash
# Destroy all resources
terraform destroy

# Confirm destruction
terraform state list  # Should be empty
```

### Step 2: Verify Cleanup
```bash
# Check for any remaining resources
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*terraform-state-demo*"
aws elbv2 describe-load-balancers --names "*terraform-state-demo*"
```

## 📊 Cost Considerations

### Resource Costs (Approximate)
- **NAT Gateways**: ~$45/month each (most expensive)
- **Load Balancer**: ~$16/month
- **EC2 Instances**: ~$8.5/month each (t2.micro)
- **RDS Instance**: ~$13/month (db.t3.micro)

### Cost Optimization
- Set `enable_nat_gateway = false` for development
- Use `t2.micro` instances (free tier eligible)
- Set `create_database = false` if not needed

## 🎯 Key Takeaways

### State Management at Scale
- ✅ Complex infrastructure requires careful state management
- ✅ Resource dependencies are automatically tracked
- ✅ State operations work the same regardless of complexity
- ✅ Remote state is essential for production workloads

### Best Practices Demonstrated
- ✅ Modular resource organization
- ✅ Proper tagging strategy
- ✅ Security group least privilege
- ✅ Multi-AZ deployment for high availability
- ✅ Separation of public and private resources

### Production Readiness
- ✅ Auto Scaling for resilience
- ✅ Load balancing for distribution
- ✅ Health checks for reliability
- ✅ Proper networking segmentation
- ✅ Database in private subnets

## 📝 Next Steps

1. **Explore Modules**: Refactor this into reusable modules
2. **Add Monitoring**: Implement CloudWatch dashboards
3. **CI/CD Integration**: Automate deployments with pipelines
4. **Multi-Environment**: Use workspaces or separate state files
5. **Advanced Features**: Add SSL certificates, WAF, etc.

This example provides a solid foundation for understanding Terraform state management in complex, real-world scenarios.