# Day 2: Intermediate Terraform
## Modular Architecture & Production Patterns

---

## Learning Objectives
By the end of Day 2, you will:
- Master variables, outputs, and locals
- Create reusable Terraform modules
- Implement environment-specific configurations
- Build production-ready infrastructure

---

## Step-by-Step Learning Path

### Step 1: Modular Architecture Deep Dive (120 minutes)
**File:** [terraform-day2-complete-modular-guide.md](terraform-day2-complete-modular-guide.md)

**Topics covered:**
- Variables with validation
- Outputs and data flow
- Local values and functions
- Module creation and usage
- Environment-specific patterns

**Expected outcome:** Understanding of modular Terraform architecture

---

### Step 2: Production Project (90 minutes)
**Directory:** [ecommerce-infrastructure/](ecommerce-infrastructure/)

**What you'll build:**
- Complete e-commerce platform
- Multi-tier architecture (Web, App, Database)
- Auto-scaling groups
- Load balancers
- Monitoring setup

**Expected outcome:** Production-ready infrastructure deployment

---

### Step 3: Knowledge Assessment (30 minutes)
**File:** [terraform-mcqs.md](terraform-mcqs.md)

**Assessment:**
- 6 application-oriented questions
- Intermediate to advanced concepts
- Minimum passing: 4/6

**Expected outcome:** Validated intermediate knowledge

---

## Project Structure Overview

```
ecommerce-infrastructure/
##œ###### main.tf                    # Root orchestration
##œ###### variables.tf               # Input variables
##œ###### outputs.tf                 # Root outputs
##œ###### locals.tf                 # Computed values
##œ###### data.tf                   # Data sources
##œ###### versions.tf               # Provider versions
##œ###### terraform.tfvars          # Default values
##œ###### 
##œ###### modules/                  # Reusable modules
##‚   ##œ###### networking/           # VPC, Subnets
##‚   ##œ###### security/             # Security Groups
##‚   ##œ###### compute/              # EC2, ASG
##‚   ##œ###### database/             # RDS
##‚   ##œ###### loadbalancer/         # ALB
##‚   ########## monitoring/           # CloudWatch
##‚
########## environments/             # Environment configs
    ##œ###### dev/
    ##œ###### staging/
    ########## prod/
```

---

## Hands-On Commands

```bash
# Navigate to project
cd 02-intermediate/ecommerce-infrastructure

# Initialize project
terraform init

# Plan for development
terraform plan -var-file="environments/dev/terraform.tfvars"

# Apply development environment
terraform apply -var-file="environments/dev/terraform.tfvars"

# Plan for production
terraform plan -var-file="environments/prod/terraform.tfvars"

# Destroy when done
terraform destroy -var-file="environments/dev/terraform.tfvars"
```

---

## Day 2 Completion Checklist

- [ ] Completed modular architecture guide
- [ ] Created your first Terraform module
- [ ] Understood variable validation patterns
- [ ] Deployed multi-environment infrastructure
- [ ] Implemented locals and data sources
- [ ] Passed intermediate MCQ assessment (4/6 minimum)
- [ ] Successfully built e-commerce platform

---

## Key Concepts Mastered

### Variables & Validation
```hcl
variable "environment" {
  validation {
    condition = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}
```

### Module Usage
```hcl
module "networking" {
  source = "./modules/networking"
  
  vpc_cidr = var.vpc_cidr
  name_prefix = local.name_prefix
  tags = local.common_tags
}
```

### Environment-Specific Configs
```hcl
locals {
  env_config = {
    dev  = { instance_type = "t3.micro" }
    prod = { instance_type = "t3.large" }
  }
  current_config = local.env_config[var.environment]
}
```

---

## Next Steps

After completing Day 2:
1. Explore [Advanced Presentations](../03-presentations/)
2. Review [Additional Resources](../04-resources/)
3. Practice with your own infrastructure projects
4. Consider Terraform certification

---

## Troubleshooting

### Common Issues:
- **Module not found:** Check module source paths
- **Variable validation errors:** Review validation conditions
- **State conflicts:** Use different state files per environment

### Best Practices:
- Always use remote state for production
- Implement proper tagging strategies
- Use consistent naming conventions
- Document your modules

---

**Ready to dive deep? Start with the [Modular Architecture Guide](terraform-day2-complete-modular-guide.md)!**