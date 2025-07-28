# Day 1: Terraform Fundamentals
## Getting Started with Infrastructure as Code

---

## Learning Objectives
By the end of Day 1, you will:
- Understand Infrastructure as Code concepts
- Install and configure Terraform
- Deploy your first AWS resource
- Understand Terraform workflow and state

---

## Step-by-Step Learning Path

### Step 1: Environment Setup (15 minutes)
**File:** [terraform-installation-guide.md](terraform-installation-guide.md)

**What you'll do:**
- Install Terraform on your system
- Configure AWS CLI
- Verify your setup

**Expected outcome:** Working Terraform and AWS CLI

---

### Step 2: Core Concepts (90 minutes)
**File:** [terraform-day01-lecture.md](terraform-day01-lecture.md)

**Topics covered:**
- Manual deployment challenges (15 min)
- Evolution of infrastructure management (20 min)
- Types of IaC tools (25 min)
- Why Terraform? (20 min)
- Terraform core concepts (25 min)
- HCL basics & first resource (20 min)

**Expected outcome:** Solid understanding of Terraform fundamentals

---

### Step 3: Hands-On Practice (60 minutes)
**File:** [terraform-complete-guide.md](terraform-complete-guide.md)

**What you'll build:**
- Your first EC2 instance
- Security groups
- Understanding state management
- Resource cleanup

**Expected outcome:** Working EC2 instance deployed via Terraform

---

### Step 4: Knowledge Assessment (15 minutes)
**File:** [terraform-basic-mcqs-day01.md](terraform-basic-mcqs-day01.md)

**Assessment:**
- 7 fundamental questions
- Covers all Day 1 concepts
- Minimum passing: 5/7

**Expected outcome:** Validated understanding of basics

---

## Quick Commands Reference

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply changes
terraform apply

# Destroy resources
terraform destroy

# Check version
terraform version

# Validate configuration
terraform validate
```

---

## Day 1 Completion Checklist

- [ ] Terraform installed and working
- [ ] AWS CLI configured with credentials
- [ ] Completed lecture notes reading
- [ ] Successfully deployed first EC2 instance
- [ ] Understood terraform.tfstate file
- [ ] Passed MCQ assessment (5/7 minimum)
- [ ] Cleaned up AWS resources

---

## Next Steps

Once you complete Day 1:
1. Move to [Day 2: Intermediate Concepts](../02-intermediate/)
2. Learn about variables, modules, and production patterns
3. Build a complete e-commerce infrastructure

---

## Troubleshooting

### Common Issues:
- **Terraform not found:** Check PATH configuration
- **AWS permissions:** Ensure proper IAM policies
- **State file conflicts:** Don't share state files between users

### Need Help?
- Review the installation guide
- Check AWS credentials: `aws sts get-caller-identity`
- Validate Terraform files: `terraform validate`

---

**Ready to start? Begin with the [Installation Guide](terraform-installation-guide.md)!**