# Production Deployment Guide - 3-Tier Application

This guide provides step-by-step instructions for deploying the 3-tier application in a production environment with enterprise-grade security, monitoring, and operational practices.

## 🎯 Production Deployment Checklist

### Pre-Deployment Requirements
- [ ] AWS account with appropriate permissions
- [ ] Terraform >= 1.0 installed
- [ ] AWS CLI configured with production credentials
- [ ] S3 backend and DynamoDB table created
- [ ] Domain name and SSL certificate (optional)
- [ ] Monitoring and alerting setup planned

## 🔐 Security Setup

### 1. IAM Roles and Policies

Create dedicated IAM roles for production deployment:

```bash
# Create Terraform execution role
aws iam create-role --role-name TerraformExecutionRole --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}'

# Attach necessary policies
aws iam attach-role-policy --role-name TerraformExecutionRole --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
```

### 2. Secrets Management

Set up AWS Secrets Manager for sensitive data:

```bash
# Create database password secret
aws secretsmanager create-secret \
  --name "3tier-app/prod/database-password" \
  --description "Production database password" \
  --secret-string "$(openssl rand -base64 32)"

# Create application secrets
aws secretsmanager create-secret \
  --name "3tier-app/prod/app-secrets" \
  --description "Application secrets" \
  --secret-string '{
    "jwt_secret": "'$(openssl rand -base64 32)'",
    "api_key": "'$(openssl rand -hex 16)'"
  }'
```

### 3. Network Security

Configure VPC Flow Logs and security monitoring:

```bash
# Enable VPC Flow Logs (add to Terraform configuration)
resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}
```

## 🚀 Production Deployment Steps

### Step 1: Environment Preparation

```bash
# Clone the repository
git clone <your-repo-url>
cd terraform/day-03/examples/3-tier-app

# Set up production environment
export AWS_PROFILE=production
export TF_VAR_environment=prod
export TF_VAR_db_password=$(aws secretsmanager get-secret-value --secret-id "3tier-app/prod/database-password" --query SecretString --output text)
```

### Step 2: Backend Configuration

Update `main.tf` with production backend:

```hcl
terraform {
  backend "s3" {
    bucket         = "company-terraform-state-prod"
    key            = "3tier-app/prod/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-locks-prod"
    
    # Additional security
    kms_key_id = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
  }
}
```

### Step 3: Production Configuration

Use the production terraform.tfvars:

```bash
# Copy production configuration
cp environments/prod/terraform.tfvars .

# Review and customize for your environment
vim terraform.tfvars
```

### Step 4: Infrastructure Validation

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Security scan (optional - use tools like tfsec)
tfsec .

# Plan deployment
terraform plan -out=prod.tfplan

# Review the plan carefully
terraform show prod.tfplan
```

### Step 5: Staged Deployment

Deploy in stages to minimize risk:

```bash
# Stage 1: Network infrastructure only
terraform apply -target=aws_vpc.main -target=aws_subnet.public -target=aws_subnet.private_app -target=aws_subnet.private_db

# Stage 2: Security groups and load balancers
terraform apply -target=aws_security_group.alb -target=aws_security_group.web -target=aws_security_group.app -target=aws_lb.main

# Stage 3: Database
terraform apply -target=aws_db_instance.main

# Stage 4: Application infrastructure
terraform apply -target=aws_autoscaling_group.web -target=aws_autoscaling_group.app

# Final: Complete deployment
terraform apply prod.tfplan
```

### Step 6: Post-Deployment Verification

```bash
# Verify all resources are created
terraform state list | wc -l

# Check application health
APP_URL=$(terraform output -raw application_url)
curl -f $APP_URL/health

# Verify database connectivity
curl -f $APP_URL/test-db.php

# Check Auto Scaling Groups
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $(terraform output -raw web_asg_name)
```

## 📊 Monitoring and Alerting Setup

### 1. CloudWatch Dashboards

Create production monitoring dashboard:

```bash
# Create custom dashboard
aws cloudwatch put-dashboard --dashboard-name "3TierApp-Production" --dashboard-body '{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "'$(terraform output -raw alb_arn | cut -d/ -f2-)'"],
          ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "'$(terraform output -raw alb_arn | cut -d/ -f2-)'"]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-west-2",
        "title": "Load Balancer Metrics"
      }
    }
  ]
}'
```

### 2. CloudWatch Alarms

Set up critical alerts:

```bash
# High CPU alarm for web tier
aws cloudwatch put-metric-alarm \
  --alarm-name "3TierApp-WebTier-HighCPU" \
  --alarm-description "Web tier high CPU utilization" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2

# Database connection alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "3TierApp-Database-Connections" \
  --alarm-description "Database connection count high" \
  --metric-name DatabaseConnections \
  --namespace AWS/RDS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2
```

### 3. Log Aggregation

Configure centralized logging:

```bash
# Create log groups
aws logs create-log-group --log-group-name "/aws/ec2/3tier-app/web"
aws logs create-log-group --log-group-name "/aws/ec2/3tier-app/app"
aws logs create-log-group --log-group-name "/aws/rds/3tier-app/error"
```

## 🔄 Backup and Disaster Recovery

### 1. Database Backups

Configure automated backups:

```hcl
# In main.tf - RDS configuration
resource "aws_db_instance" "main" {
  # ... other configuration ...
  
  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  copy_tags_to_snapshot  = true
  delete_automated_backups = false
  
  # Point-in-time recovery
  enabled_cloudwatch_logs_exports = ["error", "general", "slow-query"]
}
```

### 2. Infrastructure State Backup

```bash
# Create automated state backup script
cat > backup-terraform-state.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d-%H%M%S)
BUCKET="company-terraform-backups"
STATE_FILE="3tier-app-prod-state-$DATE.json"

# Pull current state
terraform state pull > $STATE_FILE

# Upload to backup bucket
aws s3 cp $STATE_FILE s3://$BUCKET/3tier-app/prod/

# Clean up local file
rm $STATE_FILE

echo "State backup completed: $STATE_FILE"
EOF

chmod +x backup-terraform-state.sh

# Set up cron job for daily backups
echo "0 2 * * * /path/to/backup-terraform-state.sh" | crontab -
```

### 3. Application Data Backup

```bash
# Create RDS snapshot
aws rds create-db-snapshot \
  --db-instance-identifier $(terraform output -raw database_endpoint | cut -d. -f1) \
  --db-snapshot-identifier "3tier-app-prod-$(date +%Y%m%d-%H%M%S)"
```

## 🔧 Operational Procedures

### 1. Scaling Operations

```bash
# Scale web tier
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name $(terraform output -raw web_asg_name) \
  --desired-capacity 5

# Scale application tier
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name $(terraform output -raw app_asg_name) \
  --desired-capacity 6
```

### 2. Rolling Updates

```bash
# Update launch template
terraform apply -target=aws_launch_template.web

# Trigger instance refresh
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name $(terraform output -raw web_asg_name) \
  --preferences MinHealthyPercentage=50,InstanceWarmup=300
```

### 3. Database Maintenance

```bash
# Apply minor version updates
aws rds modify-db-instance \
  --db-instance-identifier $(terraform output -raw database_endpoint | cut -d. -f1) \
  --auto-minor-version-upgrade \
  --apply-immediately
```

## 🚨 Incident Response

### 1. Application Down

```bash
# Check load balancer health
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw alb_arn | sed 's/loadbalancer/targetgroup/')

# Check Auto Scaling Group
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $(terraform output -raw web_asg_name)

# Force instance replacement
aws autoscaling terminate-instance-in-auto-scaling-group \
  --instance-id <instance-id> \
  --should-decrement-desired-capacity
```

### 2. Database Issues

```bash
# Check RDS status
aws rds describe-db-instances \
  --db-instance-identifier $(terraform output -raw database_endpoint | cut -d. -f1)

# Check recent events
aws rds describe-events \
  --source-identifier $(terraform output -raw database_endpoint | cut -d. -f1) \
  --source-type db-instance
```

### 3. State File Recovery

```bash
# List available backups
aws s3 ls s3://company-terraform-backups/3tier-app/prod/

# Download backup
aws s3 cp s3://company-terraform-backups/3tier-app/prod/3tier-app-prod-state-YYYYMMDD-HHMMSS.json ./

# Restore state
terraform state push 3tier-app-prod-state-YYYYMMDD-HHMMSS.json
```

## 📋 Production Checklist

### Pre-Go-Live
- [ ] All security groups reviewed and approved
- [ ] Database passwords rotated and stored in Secrets Manager
- [ ] SSL certificates installed and configured
- [ ] Monitoring and alerting configured
- [ ] Backup procedures tested
- [ ] Disaster recovery plan documented
- [ ] Load testing completed
- [ ] Security scan passed
- [ ] Change management approval obtained

### Post-Go-Live
- [ ] Application health verified
- [ ] All monitoring dashboards functional
- [ ] Backup jobs scheduled and tested
- [ ] Documentation updated
- [ ] Team trained on operational procedures
- [ ] Incident response procedures tested
- [ ] Performance baseline established
- [ ] Cost monitoring configured

## 🎯 Best Practices Summary

### Security
- ✅ Use IAM roles instead of access keys
- ✅ Enable encryption at rest and in transit
- ✅ Implement least privilege access
- ✅ Regular security audits and updates
- ✅ Network segmentation with security groups

### Reliability
- ✅ Multi-AZ deployment for high availability
- ✅ Auto Scaling for resilience
- ✅ Health checks and automatic recovery
- ✅ Regular backup and recovery testing
- ✅ Monitoring and alerting

### Performance
- ✅ Right-sizing instances based on metrics
- ✅ Load balancing across multiple AZs
- ✅ Database performance monitoring
- ✅ Application performance monitoring
- ✅ Regular performance testing

### Cost Optimization
- ✅ Reserved instances for predictable workloads
- ✅ Spot instances for non-critical workloads
- ✅ Auto Scaling to match demand
- ✅ Regular cost reviews and optimization
- ✅ Resource tagging for cost allocation

This production deployment guide ensures your 3-tier application is deployed with enterprise-grade practices, security, and operational excellence.