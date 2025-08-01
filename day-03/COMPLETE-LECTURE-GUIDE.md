# Day 03: Terraform State Management - Complete Lecture Guide

## 🎯 Overview
This single guide contains everything you need to teach Terraform state management from basic concepts to production deployment.

---

## 📚 PART 1: BASIC STATE (Local State Demo)

### Navigate to Basic State Example
```bash
cd day-03/examples/basic-state
```

### Step 1: Initialize and Deploy
```bash
terraform init
terraform plan
terraform apply
```

### Step 2: Examine Local State
```bash
# View state file
cat terraform.tfstate | jq '.'

# List resources
terraform state list

# Show specific resource
terraform state show aws_instance.web

# Check state metadata
cat terraform.tfstate | jq '{version, terraform_version, serial, lineage}'
```

### Step 3: State Operations Demo
```bash
# Remove from state (keeps AWS resource)
terraform state rm aws_security_group.web_sg

# Check what happens
terraform plan

# Re-import
SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=terraform-state-demo-*" --query 'SecurityGroups[0].GroupId' --output text)
terraform import aws_security_group.web_sg $SG_ID
```

### Key Points to Explain:
- State file is local JSON file
- Contains resource mappings and metadata
- No team collaboration or locking
- Security concerns with local storage

---

## 🌐 PART 2: REMOTE STATE (S3 + DynamoDB)

### Navigate to Clean Remote State Example
```bash
cd ../remote-state-clean
```

### Phase 1: Create Backend Infrastructure
```bash
# Copy backend setup
cp 01-backend-setup.tf main.tf

# Create S3 bucket and DynamoDB table
terraform init
terraform apply

# Get bucket name
BUCKET_NAME=$(terraform output -raw s3_bucket_name)
echo "Bucket: $BUCKET_NAME"
```

### Phase 2: Switch to Remote Backend
```bash
# Clean up local state
rm main.tf terraform.tfstate*

# Copy infrastructure config
cp 02-main-infrastructure.tf main.tf

# Update with real bucket name
sed -i "s/terraform-state-demo-XXXXXXXX/$BUCKET_NAME/g" main.tf

# Initialize with remote backend
terraform init
```

### Phase 3: Deploy with Remote State
```bash
# Deploy infrastructure
terraform apply

# Verify no local state
ls -la terraform.tfstate*

# List resources from remote state
terraform state list

# Pull remote state
terraform state pull > remote-state.json
cat remote-state.json | jq '.resources | length'
```

### Phase 4: Demonstrate State Locking
```bash
# Terminal 1: Start long operation
terraform apply &

# Terminal 2: Try another operation (blocked)
terraform plan
# Shows: Error acquiring the state lock

# Check DynamoDB for locks
aws dynamodb scan --table-name terraform-state-locks
```

### Key Points to Explain:
- State stored in S3 with encryption
- DynamoDB provides state locking
- Enables team collaboration
- Automatic backup and versioning

---

## 🏗️ PART 3: PRODUCTION 3-TIER APPLICATION

### Navigate to 3-Tier App
```bash
cd ../3-tier-app
```

### Show Architecture Overview
```bash
# Show file structure
ls -la

# Count lines of infrastructure code
wc -l main.tf

# Show resource types
grep "resource \"" main.tf | cut -d'"' -f2 | sort | uniq -c
```

### Configure for Demo
```bash
# Copy dev configuration
cp environments/dev/terraform.tfvars .

# Update backend with your bucket
sed -i "s/terraform-state-demo-12345678/$BUCKET_NAME/g" main.tf
```

### Deploy Production Architecture
```bash
# Initialize
terraform init

# Plan (show complexity)
terraform plan | grep "Plan:"

# Apply (if time permits)
terraform apply
```

### Demonstrate State at Scale
```bash
# List all resources (50+ resources)
terraform state list | wc -l

# Show resource dependencies
terraform show -json | jq '.values.root_module.resources[] | select(.address=="aws_autoscaling_group.web") | .depends_on'

# Show state file size
terraform state pull | wc -c
```

### Key Points to Explain:
- Complex infrastructure with 50+ resources
- Multi-tier architecture patterns
- Production-ready with Auto Scaling, Load Balancers
- State management at enterprise scale

---

## 🔧 PART 4: STATE OPERATIONS DEEP DIVE

### Essential State Commands
```bash
# Inspection commands
terraform state list
terraform state show <resource>
terraform show

# Manipulation commands
terraform state rm <resource>
terraform state mv <old> <new>
terraform import <resource> <id>

# Backup and recovery
terraform state pull > backup.json
terraform state push backup.json

# Refresh operations
terraform refresh
terraform apply -refresh-only
```

### Practical Examples
```bash
# Remove and re-import example
terraform state rm aws_security_group.web
terraform plan  # Shows resource to be created
terraform import aws_security_group.web sg-12345678

# Rename resource in state
terraform state mv aws_instance.web aws_instance.web_server

# Backup state
terraform state pull > state-backup-$(date +%Y%m%d).json
```

---

## 📊 COMPARISON TABLE

| Aspect | Local State | Remote State | Production Scale |
|--------|-------------|--------------|------------------|
| **Storage** | Local file | S3 bucket | S3 + versioning |
| **Team Work** | ❌ No | ✅ Yes | ✅ Yes |
| **Locking** | ❌ No | ✅ DynamoDB | ✅ DynamoDB |
| **Encryption** | ❌ No | ✅ Yes | ✅ Yes + KMS |
| **Backup** | Manual | Automatic | Automated + DR |
| **Resources** | 1-5 | 5-20 | 50+ |
| **Use Case** | Learning | Team projects | Enterprise |

---

## 🎯 KEY CONCEPTS TO EMPHASIZE

### State Fundamentals
- **State is the mapping** between configuration and real resources
- **State enables updates** - Terraform knows what exists
- **State tracks metadata** - dependencies, attributes, etc.
- **State is sensitive** - contains resource details

### Local vs Remote State
- **Local**: Simple but limited, no collaboration
- **Remote**: Production-ready, team collaboration, locking
- **Always use remote** for any team or production work

### State Security
- **Encrypt state files** (S3 encryption, KMS)
- **Control access** (IAM policies)
- **Enable versioning** (S3 versioning)
- **Regular backups** (automated backup strategies)

### State Operations
- **Never edit manually** - always use terraform commands
- **Backup before operations** - state pull before changes
- **Import existing resources** - bring unmanaged resources into state
- **State locking prevents corruption** - automatic with remote backends

---

## 🧹 CLEANUP COMMANDS

### Clean Up All Examples
```bash
# Clean up 3-tier app
cd day-03/examples/3-tier-app
terraform destroy

# Clean up remote state demo
cd ../remote-state-clean
terraform destroy

# Clean up backend (optional)
cp 01-backend-setup.tf main.tf
terraform init
terraform destroy

# Clean up basic state
cd ../basic-state
terraform destroy
```

---

## 📝 LECTURE TIMING (90 minutes)

- **Part 1 - Basic State**: 20 minutes
- **Part 2 - Remote State**: 30 minutes  
- **Part 3 - Production Demo**: 25 minutes
- **Part 4 - State Operations**: 15 minutes

---

## 🎓 STUDENT TAKEAWAYS

By the end of this lecture, students will:

1. **Understand** what Terraform state is and why it's critical
2. **Know the difference** between local and remote state
3. **Be able to set up** S3 backend with DynamoDB locking
4. **Perform basic state operations** (list, show, rm, import)
5. **Understand** state management at production scale
6. **Know best practices** for state security and backup

---

## ⚠️ TROUBLESHOOTING

### Common Issues
- **Bucket doesn't exist**: Run backend setup first
- **Duplicate resources**: Use clean examples in separate directories
- **State locked**: Use `terraform force-unlock <LOCK_ID>`
- **Import fails**: Check resource ID format

### Quick Fixes
```bash
# Reset if confused
rm -rf .terraform terraform.tfstate*
terraform init

# Force unlock if stuck
terraform force-unlock <LOCK_ID>

# Start fresh
git reset --hard origin/main
```

---

This single guide contains everything you need to deliver a comprehensive Terraform state management lecture. Follow the sections in order, use the copy-paste commands, and emphasize the key concepts highlighted above.