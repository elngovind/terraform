# Day 2 Hands-On Project: E-Commerce Infrastructure
## Building Production-Ready Modular Architecture

**Duration:** 90 minutes | **Prerequisites:** Day 2 lecture completed

---

## Project Overview

Build a complete e-commerce platform infrastructure using modular Terraform architecture with:
- Multi-tier architecture (Web, App, Database)
- Auto-scaling capabilities
- Load balancing
- Environment-specific configurations

---

## Architecture Diagram

```
Production E-Commerce Infrastructure:
├── Public Tier (Load Balancers)
├── Web Tier (Frontend Servers)
├── Application Tier (Backend APIs)
├── Database Tier (RDS with replicas)
├── Monitoring (CloudWatch, SNS)
└── Security (WAF, Security Groups)
```

---

## Project Structure

The complete project is located in the `ecommerce-project/` directory:

```
ecommerce-project/
├── main.tf                    # Root module orchestration
├── variables.tf               # Input variables
├── outputs.tf                 # Root outputs
├── locals.tf                 # Computed values
├── data.tf                   # Data sources
├── versions.tf               # Provider versions
├── terraform.tfvars          # Default values
├── 
├── modules/                  # Reusable modules
│   ├── networking/           # VPC, Subnets
│   ├── security/             # Security Groups
│   ├── compute/              # EC2, ASG
│   ├── database/             # RDS
│   ├── loadbalancer/         # ALB
│   └── monitoring/           # CloudWatch
│
└── environments/             # Environment configs
    ├── dev/
    ├── staging/
    └── prod/
```

---

## Step-by-Step Implementation

### Step 1: Initialize Project (10 minutes)

```bash
# Navigate to project directory
cd ecommerce-project

# Initialize Terraform
terraform init

# Validate configuration
terraform validate
```

### Step 2: Review Module Architecture (20 minutes)

Examine each module:
1. **Networking Module** - VPC, subnets, routing
2. **Security Module** - Security groups, NACLs
3. **Compute Module** - EC2 instances, Auto Scaling Groups
4. **Database Module** - RDS with read replicas
5. **Load Balancer Module** - Application Load Balancer
6. **Monitoring Module** - CloudWatch, SNS

### Step 3: Deploy Development Environment (30 minutes)

```bash
# Plan deployment for development
terraform plan -var-file="environments/dev/terraform.tfvars"

# Apply configuration
terraform apply -var-file="environments/dev/terraform.tfvars"

# Verify deployment
terraform output
```

### Step 4: Test the Infrastructure (15 minutes)

1. Access the load balancer URL
2. Verify auto-scaling configuration
3. Check database connectivity
4. Review CloudWatch metrics

### Step 5: Environment Comparison (10 minutes)

Compare configurations:
```bash
# View staging configuration
cat environments/staging/terraform.tfvars

# View production configuration
cat environments/prod/terraform.tfvars
```

### Step 6: Cleanup (5 minutes)

```bash
# Destroy development environment
terraform destroy -var-file="environments/dev/terraform.tfvars"
```

---

## Key Learning Points

### Module Design Patterns
- **Input validation** using variable constraints
- **Output organization** for data sharing
- **Resource tagging** for management
- **Error handling** and validation

### Environment Management
- **Configuration separation** by environment
- **Resource sizing** based on environment
- **Feature toggles** for different environments

### Production Readiness
- **High availability** across multiple AZs
- **Auto-scaling** for dynamic load
- **Monitoring** and alerting
- **Security** best practices

---

## Troubleshooting Common Issues

### Module Not Found
```bash
# Ensure modules are in correct location
ls -la modules/

# Re-initialize if needed
terraform init
```

### Variable Validation Errors
```bash
# Check variable values
terraform console
> var.environment
```

### State Conflicts
```bash
# Use different state files per environment
terraform init -backend-config="key=dev/terraform.tfstate"
```

---

## Extension Exercises

### Exercise 1: Add Monitoring
Add CloudWatch alarms for:
- CPU utilization
- Database connections
- Load balancer response time

### Exercise 2: Implement Blue-Green Deployment
Modify the compute module to support:
- Multiple deployment slots
- Traffic switching capability
- Rollback mechanisms

### Exercise 3: Add Security Enhancements
Implement:
- WAF rules
- VPC Flow Logs
- GuardDuty integration

---

## Project Completion Checklist

- [ ] Project initialized successfully
- [ ] All modules reviewed and understood
- [ ] Development environment deployed
- [ ] Infrastructure tested and verified
- [ ] Environment configurations compared
- [ ] Resources cleaned up properly
- [ ] Extension exercises attempted (optional)

---

## Next Steps

After completing this project:
1. Complete the [Day 2 Assessment](04-assessment.md)
2. Work on the [Day 2 Assignment](../assignments/day-02-assignment.md)
3. Prepare for Day 3 (coming soon)

---

**Project files are located in the [ecommerce-project/](ecommerce-project/) directory.**