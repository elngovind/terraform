# Day 2: Modular Architecture & Best Practices
## Advanced Terraform Concepts

**Duration:** 3 hours | **Level:** Intermediate | **Prerequisites:** Day 1 completed

---

## Learning Objectives

By the end of Day 2, you will:
- Master variables, outputs, and locals
- Create reusable Terraform modules
- Implement environment-specific configurations
- Build production-ready infrastructure
- Apply Terraform best practices

---

## Class Schedule

### Session 1: Advanced Concepts (90 minutes)
**File:** [01-lecture-notes.md](01-lecture-notes.md)
- Variables with validation
- Outputs and data flow
- Local values and functions
- Module architecture principles
- Environment management strategies

### Session 2: Modular Design (30 minutes)
**File:** [02-modular-guide.md](02-modular-guide.md)
- Module creation patterns
- Best practices for module design
- Module composition strategies

### Session 3: Hands-On Project (90 minutes)
**File:** [03-hands-on-project.md](03-hands-on-project.md)
- Build complete e-commerce infrastructure
- Implement modular architecture
- Deploy across multiple environments
- Test and validate deployment

### Session 4: Assessment (15 minutes)
**File:** [04-assessment.md](04-assessment.md)
- 6 application-oriented questions
- Minimum passing score: 4/6

---

## Prerequisites

- Day 1 completed successfully
- Terraform and AWS CLI configured
- Basic understanding of AWS services

---

## Project Structure

Today's main project is located in `ecommerce-project/`:
- Complete modular e-commerce platform
- Multi-tier architecture
- Environment-specific configurations
- Production-ready patterns

---

## Completion Checklist

- [ ] Advanced concepts lecture completed
- [ ] Module design principles understood
- [ ] E-commerce project deployed successfully
- [ ] Multiple environments configured
- [ ] Infrastructure tested and verified
- [ ] Assessment passed (4/6 minimum)
- [ ] Day 2 assignment completed

---

## Key Concepts Covered

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
1. Complete the [Day 2 Assignment](../assignments/day-02-assignment.md)
2. Review any challenging concepts
3. Prepare for Day 3: Advanced Terraform Features (coming soon)

---

## Troubleshooting

### Common Issues
- **Module not found:** Check module source paths
- **Variable validation errors:** Review validation conditions
- **State conflicts:** Use different state files per environment

### Getting Help
- Check the [troubleshooting guide](../resources/troubleshooting.md)
- Review module documentation
- Create issues for specific problems

---

**Ready to dive into advanced Terraform? Start with [Lecture Notes](01-lecture-notes.md)!**