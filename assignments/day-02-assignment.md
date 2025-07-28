# Day 2 Assignment: Modular Infrastructure Design
## Advanced Homework Assignment

**Due:** Before Day 3 class | **Estimated Time:** 3 hours

---

## Assignment Overview

Design and implement a modular Terraform architecture for a real-world scenario. This assignment tests your understanding of modules, variables, and environment management.

---

## Scenario: Blog Platform Infrastructure

You're tasked with creating infrastructure for a blog platform that needs:
- Development and production environments
- Web servers with auto-scaling
- Database with backup strategy
- Content delivery network (CDN)
- Monitoring and alerting

---

## Assignment Tasks

### Task 1: Module Design (90 minutes)

Create the following modules:

#### A. Networking Module (`modules/networking/`)
- VPC with public and private subnets
- Internet Gateway and NAT Gateway
- Route tables and associations
- Network ACLs

#### B. Security Module (`modules/security/`)
- Security groups for web, app, and database tiers
- IAM roles and policies
- Key pair management

#### C. Compute Module (`modules/compute/`)
- Launch template for web servers
- Auto Scaling Group
- Application Load Balancer
- Target groups and health checks

#### D. Database Module (`modules/database/`)
- RDS instance with Multi-AZ
- Database subnet group
- Parameter group
- Backup configuration

**Requirements for each module:**
- Proper variable validation
- Comprehensive outputs
- Resource tagging
- Documentation (README.md)

### Task 2: Environment Configuration (45 minutes)

Create environment-specific configurations:

#### Development Environment
- Single AZ deployment
- t3.micro instances
- db.t3.micro database
- Minimal monitoring

#### Production Environment
- Multi-AZ deployment
- t3.medium instances
- db.r5.large database
- Full monitoring and alerting

**Files needed:**
- `environments/dev/terraform.tfvars`
- `environments/prod/terraform.tfvars`
- `environments/dev/backend.tf`
- `environments/prod/backend.tf`

### Task 3: Root Configuration (30 minutes)

Create root module files:
- `main.tf` - Module orchestration
- `variables.tf` - Input variables with validation
- `outputs.tf` - Important outputs
- `locals.tf` - Environment-specific logic
- `versions.tf` - Provider requirements

### Task 4: Testing and Validation (30 minutes)

1. Deploy development environment
2. Verify all components work together
3. Test auto-scaling functionality
4. Validate database connectivity
5. Document any issues and resolutions

### Task 5: Documentation (15 minutes)

Create comprehensive documentation:
- Architecture diagram (can be text-based)
- Deployment instructions
- Environment differences
- Troubleshooting guide

---

## Bonus Challenges (Optional)

### Bonus 1: Monitoring Module
Create a monitoring module with:
- CloudWatch alarms
- SNS topics for notifications
- Dashboard for key metrics

### Bonus 2: CI/CD Integration
Add configuration for:
- S3 backend for state storage
- DynamoDB for state locking
- GitHub Actions workflow

### Bonus 3: Cost Optimization
Implement:
- Spot instances for development
- Scheduled scaling policies
- Resource lifecycle management

---

## Technical Requirements

### Code Quality
- Use consistent naming conventions
- Implement proper variable validation
- Include meaningful descriptions
- Follow Terraform best practices

### Security
- No hardcoded secrets
- Least privilege access
- Encrypted storage where applicable
- Secure network configurations

### Scalability
- Environment-agnostic modules
- Configurable resource sizing
- Support for multiple regions

---

## Submission Guidelines

### File Structure
```
day-02-assignment/
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── locals.tf
├── versions.tf
├── 
├── modules/
│   ├── networking/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── security/
│   ├── compute/
│   └── database/
├── 
├── environments/
│   ├── dev/
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   └── prod/
│       ├── terraform.tfvars
│       └── backend.tf
├── 
├── docs/
│   ├── architecture.md
│   ├── deployment.md
│   └── troubleshooting.md
└── 
└── screenshots/
    ├── dev-deployment.png
    ├── prod-plan.png
    └── architecture-diagram.png
```

### Deliverables
1. Complete modular Terraform configuration
2. Environment-specific configurations
3. Comprehensive documentation
4. Screenshots of successful deployment
5. Testing results and validation

---

## Evaluation Criteria

### Module Design (40%)
- Proper module structure
- Variable validation and outputs
- Reusability and flexibility
- Code quality and documentation

### Environment Management (25%)
- Clear environment separation
- Appropriate resource sizing
- Configuration management

### Technical Implementation (20%)
- Successful deployment
- Resource integration
- Security best practices

### Documentation (15%)
- Clear architecture description
- Deployment instructions
- Troubleshooting guide

---

## Sample Module Structure

```hcl
# modules/networking/variables.tf
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

# modules/networking/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

# modules/networking/outputs.tf
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}
```

---

## Common Challenges and Tips

### Module Dependencies
- Use outputs to pass data between modules
- Avoid circular dependencies
- Plan module order carefully

### Variable Management
- Use locals for computed values
- Validate inputs at module boundaries
- Provide sensible defaults

### Environment Differences
- Use maps for environment-specific values
- Keep differences in variables, not code
- Test both environments

---

## Assignment Checklist

- [ ] All four modules created and documented
- [ ] Environment configurations completed
- [ ] Root configuration implemented
- [ ] Development environment deployed successfully
- [ ] Production environment planned (not deployed)
- [ ] Documentation completed
- [ ] Screenshots captured
- [ ] Repository organized and shared

---

**This assignment will demonstrate your mastery of modular Terraform architecture. Take your time to design clean, reusable modules!**