# Terraform State Operations - Practical Guide

## 🔍 State Inspection Commands

### 1. List All Resources
```bash
# Basic listing
terraform state list

# Example output:
# aws_vpc.main
# aws_subnet.public[0]
# aws_subnet.public[1]
# aws_instance.web
# aws_security_group.web_sg
```

### 2. Show Resource Details
```bash
# Show specific resource
terraform state show aws_instance.web

# Example output:
# resource "aws_instance" "web" {
#     ami                    = "ami-0c02fb55956c7d316"
#     instance_type         = "t2.micro"
#     id                    = "i-1234567890abcdef0"
#     public_ip             = "54.123.45.67"
#     vpc_security_group_ids = ["sg-12345678"]
# }
```

### 3. Show All State Information
```bash
# Human-readable state output
terraform show

# JSON format output
terraform show -json > state-output.json
```

## 🔧 State Manipulation Commands

### 1. Remove Resources from State
```bash
# Remove single resource (resource remains in AWS)
terraform state rm aws_instance.web

# Remove multiple resources
terraform state rm aws_instance.web aws_security_group.web_sg

# Remove resource with count/for_each
terraform state rm 'aws_subnet.public[0]'
terraform state rm 'aws_subnet.public[1]'
```

**⚠️ Important:** `terraform state rm` only removes from state file, not from actual infrastructure!

### 2. Move/Rename Resources
```bash
# Rename resource in state
terraform state mv aws_instance.web aws_instance.web_server

# Move resource to module
terraform state mv aws_instance.web module.compute.aws_instance.web

# Move from module to root
terraform state mv module.compute.aws_instance.web aws_instance.web
```

### 3. Import Existing Resources
```bash
# Import EC2 instance
terraform import aws_instance.web i-1234567890abcdef0

# Import VPC
terraform import aws_vpc.main vpc-12345678

# Import security group
terraform import aws_security_group.web_sg sg-12345678
```

## 📥 State Pull/Push Operations

### 1. Pull Remote State
```bash
# Download remote state to local file
terraform state pull > current-state.json

# Verify the pulled state
cat current-state.json | jq '.resources[].type' | sort | uniq -c
```

### 2. Push Local State
```bash
# Upload local state to remote backend
terraform state push current-state.json

# Force push (use with extreme caution)
terraform state push -force current-state.json
```

## 🔄 State Refresh Operations

### 1. Refresh State
```bash
# Update state with current infrastructure
terraform refresh

# Refresh specific resource
terraform refresh -target=aws_instance.web

# Refresh and show changes
terraform plan -refresh-only
```

### 2. Apply Refresh-Only
```bash
# Apply only refresh changes (Terraform 0.15.4+)
terraform apply -refresh-only

# Auto-approve refresh changes
terraform apply -refresh-only -auto-approve
```

## 🔒 State Locking Operations

### 1. Check Lock Status
```bash
# View current state (shows lock info if locked)
terraform show

# Force unlock (emergency use only)
terraform force-unlock LOCK_ID
```

### 2. Manual Locking (Advanced)
```bash
# Lock state manually (rarely needed)
terraform state lock

# Unlock state manually
terraform state unlock
```

## 📊 State Analysis and Debugging

### 1. State File Analysis
```bash
# Count resources by type
terraform state list | cut -d. -f1 | sort | uniq -c

# Find specific resource types
terraform state list | grep aws_instance

# Show state file metadata
terraform state pull | jq '{version, terraform_version, serial, lineage}'
```

### 2. Dependency Analysis
```bash
# Show resource dependencies
terraform show -json | jq '.values.root_module.resources[] | select(.address=="aws_instance.web") | .depends_on'

# Visualize dependencies (requires graphviz)
terraform graph | dot -Tpng > dependency-graph.png
```

## 🛠️ Practical State Operations Examples

### Example 1: Resource Renaming
```bash
# Initial state
terraform state list
# aws_instance.server

# Rename in configuration file
# resource "aws_instance" "web_server" {  # Changed from "server"

# Update state to match
terraform state mv aws_instance.server aws_instance.web_server

# Verify no changes needed
terraform plan
```

### Example 2: Module Refactoring
```bash
# Move resources into module
terraform state mv aws_instance.web module.compute.aws_instance.web
terraform state mv aws_security_group.web_sg module.security.aws_security_group.web_sg

# Verify structure
terraform state list
# module.compute.aws_instance.web
# module.security.aws_security_group.web_sg
```

### Example 3: Import Existing Infrastructure
```bash
# Step 1: Create resource configuration
cat > import-example.tf << EOF
resource "aws_instance" "existing" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
  
  tags = {
    Name = "Existing Instance"
  }
}
EOF

# Step 2: Import the resource
terraform import aws_instance.existing i-1234567890abcdef0

# Step 3: Update configuration to match
terraform plan
# Review and update configuration as needed

# Step 4: Apply any necessary changes
terraform apply
```

## 🔍 State Troubleshooting

### Common Issues and Solutions

#### Issue 1: State Lock Stuck
```bash
# Check lock status
terraform state pull

# If lock is stuck, force unlock
terraform force-unlock <LOCK_ID>

# Example:
terraform force-unlock 12345678-1234-1234-1234-123456789012
```

#### Issue 2: State Drift Detection
```bash
# Detect configuration drift
terraform plan -detailed-exitcode
# Exit code 0: No changes
# Exit code 1: Error
# Exit code 2: Changes detected

# Fix drift by refreshing
terraform apply -refresh-only
```

#### Issue 3: Corrupted State Recovery
```bash
# Backup current state
terraform state pull > corrupted-state-backup.json

# Restore from S3 version (if using S3 backend)
aws s3api list-object-versions --bucket terraform-state-bucket --prefix terraform.tfstate

# Download specific version
aws s3api get-object --bucket terraform-state-bucket --key terraform.tfstate --version-id <VERSION_ID> restored-state.json

# Push restored state
terraform state push restored-state.json
```

## 📋 State Operations Checklist

### Before State Operations:
- [ ] Backup current state: `terraform state pull > backup.json`
- [ ] Ensure no one else is working on infrastructure
- [ ] Review planned changes carefully
- [ ] Test in non-production environment first

### During State Operations:
- [ ] Use specific resource addresses
- [ ] Verify each operation: `terraform state list`
- [ ] Check for unintended changes: `terraform plan`
- [ ] Document what you're doing

### After State Operations:
- [ ] Verify state consistency: `terraform plan`
- [ ] Test infrastructure functionality
- [ ] Update team on changes made
- [ ] Commit configuration changes to version control

## 🎯 Best Practices

1. **Always backup state** before manipulation
2. **Use specific resource addresses** to avoid mistakes
3. **Test operations** in non-production first
4. **Coordinate with team** before state changes
5. **Document state operations** for audit trail
6. **Verify results** with `terraform plan`
7. **Use version control** for configuration changes

## 📝 Quick Reference

| Command | Purpose | Example |
|---------|---------|---------|
| `terraform state list` | List all resources | `terraform state list` |
| `terraform state show` | Show resource details | `terraform state show aws_instance.web` |
| `terraform state rm` | Remove from state | `terraform state rm aws_instance.web` |
| `terraform state mv` | Move/rename resource | `terraform state mv aws_instance.web aws_instance.server` |
| `terraform import` | Import existing resource | `terraform import aws_instance.web i-1234567890abcdef0` |
| `terraform state pull` | Download remote state | `terraform state pull > backup.json` |
| `terraform state push` | Upload local state | `terraform state push backup.json` |
| `terraform refresh` | Update state from infrastructure | `terraform refresh` |
| `terraform force-unlock` | Force unlock state | `terraform force-unlock LOCK_ID` |