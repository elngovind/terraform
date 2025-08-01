# 3-Tier Application Infrastructure

This example demonstrates a **production-ready 3-tier application architecture** with comprehensive state management, showcasing enterprise-level infrastructure patterns.

## 🏗️ Architecture Overview

```
                    Internet
                        |
                 [Load Balancer]
                        |
    ┌─────────────────────────────────────────┐
    │             TIER 1: WEB LAYER           │
    │  ┌─────────┐  ┌─────────┐  ┌─────────┐  │
    │  │Web Srv 1│  │Web Srv 2│  │Web Srv N│  │
    │  └─────────┘  └─────────┘  └─────────┘  │
    └─────────────────────────────────────────┘
                        |
              [Internal Load Balancer]
                        |
    ┌─────────────────────────────────────────┐
    │         TIER 2: APPLICATION LAYER       │
    │  ┌─────────┐  ┌─────────┐  ┌─────────┐  │
    │  │App Srv 1│  │App Srv 2│  │App Srv N│  │
    │  └─────────┘  └─────────┘  └─────────┘  │
    └─────────────────────────────────────────┘
                        |
    ┌─────────────────────────────────────────┐
    │          TIER 3: DATABASE LAYER         │
    │         ┌─────────────────────┐         │
    │         │    RDS MySQL        │         │
    │         │   (Multi-AZ)        │         │
    │         └─────────────────────┘         │
    └─────────────────────────────────────────┘
```

## 🎯 Key Features

### Production-Ready Components
- ✅ **Multi-AZ deployment** across 2-3 availability zones
- ✅ **Auto Scaling Groups** for web and application tiers
- ✅ **Application Load Balancers** (external and internal)
- ✅ **RDS MySQL** with Multi-AZ and automated backups
- ✅ **NAT Gateways** for secure private subnet internet access
- ✅ **Security Groups** with least privilege access
- ✅ **Bastion Host** for secure SSH access (optional)

### State Management Features
- ✅ **Remote S3 backend** with state locking
- ✅ **Environment-specific configurations**
- ✅ **Resource tagging** and organization
- ✅ **State file encryption** and versioning

### Application Features
- ✅ **PHP web interface** with real-time metrics
- ✅ **Node.js API server** with database connectivity
- ✅ **Health checks** and monitoring endpoints
- ✅ **CloudWatch integration** for logging and metrics

## 📁 Project Structure

```
3-tier-app/
├── main.tf                    # Main infrastructure configuration
├── variables.tf               # Input variables with validation
├── outputs.tf                 # Comprehensive outputs
├── user_data/
│   ├── web_server.sh         # Web tier setup script
│   └── app_server.sh         # Application tier setup script
├── environments/
│   ├── dev/
│   │   └── terraform.tfvars  # Development configuration
│   ├── staging/
│   │   └── terraform.tfvars  # Staging configuration
│   └── prod/
│       └── terraform.tfvars  # Production configuration
└── README.md                 # This file
```

## 🚀 Deployment Instructions

### Prerequisites
1. **AWS CLI configured** with appropriate permissions
2. **Terraform >= 1.0** installed
3. **S3 backend** set up (from remote-state example)
4. **Environment variables** for sensitive data

### Step 1: Configure Backend
Update the S3 backend configuration in `main.tf`:
```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"  # Update this!
    key            = "3-tier-app/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}
```

### Step 2: Choose Environment Configuration

#### For Development:
```bash
# Copy dev configuration
cp environments/dev/terraform.tfvars .

# Initialize and deploy
terraform init
terraform plan
terraform apply
```

#### For Production:
```bash
# Copy prod configuration
cp environments/prod/terraform.tfvars .

# Set database password securely
export TF_VAR_db_password="your-secure-password"

# Initialize and deploy
terraform init
terraform plan
terraform apply
```

### Step 3: Verify Deployment
```bash
# Get application URL
terraform output application_url

# Check infrastructure summary
terraform output infrastructure_summary

# View cost estimation
terraform output estimated_monthly_cost
```

## 🔍 State Management Demonstrations

### 1. Multi-Environment State Management
```bash
# Development environment
terraform workspace new dev
terraform apply -var-file="environments/dev/terraform.tfvars"

# Production environment  
terraform workspace new prod
terraform apply -var-file="environments/prod/terraform.tfvars"

# List workspaces
terraform workspace list
```

### 2. Complex State Operations
```bash
# List all resources (50+ resources)
terraform state list | wc -l

# Show Auto Scaling Group state
terraform state show aws_autoscaling_group.web

# Show database state
terraform state show aws_db_instance.main

# Analyze resource dependencies
terraform show -json | jq '.values.root_module.resources[] | select(.address=="aws_autoscaling_group.web") | .depends_on'
```

### 3. State Backup for Production
```bash
# Create comprehensive backup
terraform state pull > 3tier-app-state-backup-$(date +%Y%m%d-%H%M%S).json

# Verify backup completeness
cat 3tier-app-state-backup-*.json | jq '.resources | length'

# Show resource types distribution
terraform state list | cut -d. -f1 | sort | uniq -c | sort -nr
```

## 🧪 Application Testing

### Access the Application
```bash
# Get the application URL
APP_URL=$(terraform output -raw application_url)
echo "Application URL: $APP_URL"

# Open in browser or test with curl
curl -s $APP_URL | grep -o '<title>.*</title>'
```

### Test API Endpoints
```bash
# Get internal ALB DNS name
APP_ALB=$(terraform output -raw app_alb_dns_name)

# Test application layer health (from bastion or web server)
curl http://$APP_ALB:8080/health
curl http://$APP_ALB:8080/info
curl http://$APP_ALB:8080/api/status
```

### Monitor Auto Scaling
```bash
# Check Auto Scaling Group status
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $(terraform output -raw web_asg_name)

# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw alb_arn | sed 's/loadbalancer/targetgroup/')
```

## 📊 Production Considerations

### Security Best Practices
- ✅ **Database in private subnets** with no internet access
- ✅ **Security groups** with minimal required access
- ✅ **Bastion host** for secure administrative access
- ✅ **IAM roles** for EC2 instances (not hardcoded credentials)
- ✅ **Encrypted storage** for RDS and EBS volumes

### High Availability
- ✅ **Multi-AZ deployment** across 2-3 availability zones
- ✅ **Auto Scaling Groups** with health checks
- ✅ **RDS Multi-AZ** for database failover
- ✅ **Load balancer health checks** with automatic failover

### Monitoring and Logging
- ✅ **CloudWatch metrics** for all tiers
- ✅ **Application logs** centralized in CloudWatch
- ✅ **Health check endpoints** for monitoring
- ✅ **Auto Scaling policies** based on metrics

### Cost Optimization
- ✅ **Environment-specific sizing** (dev vs prod)
- ✅ **Spot instances** option for non-critical workloads
- ✅ **RDS storage autoscaling** to optimize costs
- ✅ **NAT Gateway** optimization for development

## 💰 Cost Analysis

### Development Environment (~$50/month)
- Web instances (1x t3.micro): ~$8.5
- App instances (1x t3.micro): ~$8.5
- Database (db.t3.micro): ~$13
- Load balancer: ~$16
- No NAT Gateway: $0

### Production Environment (~$400/month)
- Web instances (3x t3.small): ~$51
- App instances (4x t3.medium): ~$136
- Database (db.t3.small Multi-AZ): ~$52
- Load balancers (2): ~$32
- NAT Gateways (3): ~$135

## 🔧 Troubleshooting

### Common Issues

#### 1. Application Not Accessible
```bash
# Check load balancer status
aws elbv2 describe-load-balancers --names $(terraform output -raw alb_dns_name)

# Check target group health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# Check security group rules
aws ec2 describe-security-groups --group-ids $(terraform output -raw alb_security_group_id)
```

#### 2. Database Connection Issues
```bash
# Test from application server
curl http://localhost:8080/db-test

# Check RDS status
aws rds describe-db-instances --db-instance-identifier $(terraform output -raw database_endpoint | cut -d. -f1)
```

#### 3. Auto Scaling Issues
```bash
# Check Auto Scaling Group events
aws autoscaling describe-scaling-activities --auto-scaling-group-name $(terraform output -raw web_asg_name)

# Check launch template
aws ec2 describe-launch-templates --launch-template-names $(terraform output -raw web_asg_name)-*
```

## 🧹 Cleanup

### Destroy Infrastructure
```bash
# Destroy all resources
terraform destroy

# Verify cleanup
terraform state list  # Should be empty

# Check for any remaining resources
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=3tier-app"
```

## 🎯 Learning Outcomes

After deploying this 3-tier application, you will understand:

### Infrastructure Concepts
- ✅ **Multi-tier architecture** design patterns
- ✅ **Load balancing** strategies and implementation
- ✅ **Auto scaling** configuration and policies
- ✅ **Network segmentation** and security

### State Management
- ✅ **Complex state file** management (50+ resources)
- ✅ **Environment-specific** configurations
- ✅ **State operations** at enterprise scale
- ✅ **Resource dependencies** in large infrastructures

### Production Readiness
- ✅ **High availability** design principles
- ✅ **Security best practices** implementation
- ✅ **Monitoring and logging** strategies
- ✅ **Cost optimization** techniques

## 📝 Next Steps

1. **Implement CI/CD**: Add GitHub Actions or Jenkins pipeline
2. **Add SSL/TLS**: Configure HTTPS with ACM certificates
3. **Implement WAF**: Add AWS WAF for application security
4. **Add Caching**: Implement ElastiCache for performance
5. **Container Migration**: Convert to ECS or EKS deployment
6. **Infrastructure Modules**: Refactor into reusable Terraform modules

This 3-tier application demonstrates enterprise-grade infrastructure management with Terraform, showcasing real-world patterns and best practices for production deployments.