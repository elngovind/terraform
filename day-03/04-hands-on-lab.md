# Day 03: Terraform State Management - Hands-On Lab

## 🎯 Lab Objectives
By the end of this lab, you will:
- Master Terraform state fundamentals
- Set up and configure remote state backends
- Perform state operations and troubleshooting
- Implement state security best practices
- Build a complete VPC/EC2 infrastructure with proper state management

## 📋 Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform installed (version >= 1.0)
- Basic understanding of AWS services (VPC, EC2, S3, DynamoDB)
- Completed Day 01 and Day 02 labs

## 🧪 Lab Exercises

### Exercise 1: Local State Fundamentals (30 minutes)

#### Objective
Understand local state file structure and basic operations.

#### Tasks

1. **Create Basic Infrastructure**
   ```bash
   cd examples/basic-state
   terraform init
   terraform plan
   terraform apply
   ```

2. **Examine State File**
   ```bash
   # View state file structure
   cat terraform.tfstate | jq '.'
   
   # List resources in state
   terraform state list
   
   # Show specific resource
   terraform state show aws_instance.web
   ```

3. **State File Analysis**
   ```bash
   # Check state metadata
   cat terraform.tfstate | jq '{version, terraform_version, serial, lineage}'
   
   # Count resources
   terraform state list | wc -l
   
   # View outputs in state
   cat terraform.tfstate | jq '.outputs'
   ```

4. **State Operations Practice**
   ```bash
   # Remove resource from state (keeps AWS resource)
   terraform state rm aws_security_group.web_sg
   
   # Verify removal
   terraform state list
   
   # Check what Terraform wants to do
   terraform plan
   
   # Re-import the security group
   SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=terraform-state-demo-*" --query 'SecurityGroups[0].GroupId' --output text)
   terraform import aws_security_group.web_sg $SG_ID
   ```

#### Expected Outcomes
- ✅ Understand state file JSON structure
- ✅ Successfully perform basic state operations
- ✅ Observe state changes after operations

### Exercise 2: Remote State Setup (45 minutes)

#### Objective
Set up S3 backend with DynamoDB locking for remote state management.

#### Tasks

1. **Create Backend Infrastructure**
   ```bash
   cd examples/remote-state
   
   # Initialize and create backend resources
   terraform init
   terraform apply
   
   # Note the outputs
   terraform output backend_configuration
   ```

2. **Configure Remote Backend**
   ```bash
   # Update main.tf with your actual bucket name
   BUCKET_NAME=$(terraform output -raw s3_bucket_name)
   echo "Update main.tf backend configuration with bucket: $BUCKET_NAME"
   
   # Edit main.tf and update the bucket name in backend configuration
   ```

3. **Migrate to Remote State**
   ```bash
   # Initialize with remote backend
   terraform init -migrate-state
   
   # Answer 'yes' when prompted to migrate state
   ```

4. **Verify Remote State**
   ```bash
   # Check no local state exists
   ls -la terraform.tfstate*
   
   # List resources from remote state
   terraform state list
   
   # Verify S3 storage
   aws s3 ls s3://$BUCKET_NAME/remote-state-demo/
   ```

#### Expected Outcomes
- ✅ Successfully create S3 bucket and DynamoDB table
- ✅ Migrate from local to remote state
- ✅ Verify state is stored in S3

### Exercise 3: State Locking Demonstration (20 minutes)

#### Objective
Understand and observe state locking in action.

#### Tasks

1. **Observe Normal Locking**
   ```bash
   # Start a terraform operation
   terraform plan
   
   # Check DynamoDB for lock entry (during operation)
   aws dynamodb scan --table-name terraform-state-locks
   ```

2. **Simulate Lock Conflict**
   ```bash
   # Terminal 1: Start long operation
   terraform apply &
   
   # Terminal 2: Try another operation (should be blocked)
   terraform plan
   ```

3. **Force Unlock (Emergency)**
   ```bash
   # If needed, force unlock (use actual lock ID)
   # terraform force-unlock <LOCK_ID>
   ```

#### Expected Outcomes
- ✅ Observe automatic state locking
- ✅ Understand lock conflict resolution
- ✅ Learn emergency unlock procedures

### Exercise 4: Advanced State Operations (30 minutes)

#### Objective
Master advanced state manipulation and troubleshooting.

#### Tasks

1. **State Backup and Recovery**
   ```bash
   # Create state backup
   terraform state pull > state-backup-$(date +%Y%m%d-%H%M%S).json
   
   # Verify backup
   cat state-backup-*.json | jq '.resources | length'
   ```

2. **Resource Import Practice**
   ```bash
   # Create a resource outside Terraform
   aws ec2 create-key-pair --key-name manual-keypair
   
   # Add to configuration
   cat >> main.tf << EOF
   resource "aws_key_pair" "manual" {
     key_name   = "manual-keypair"
     public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..."  # Add your public key
   }
   EOF
   
   # Import the resource
   terraform import aws_key_pair.manual manual-keypair
   
   # Verify import
   terraform plan
   ```

3. **State Drift Detection**
   ```bash
   # Manually modify a resource outside Terraform
   INSTANCE_ID=$(terraform output -raw instance_id)
   aws ec2 create-tags --resources $INSTANCE_ID --tags Key=ManualTag,Value=AddedOutsideTerraform
   
   # Detect drift
   terraform plan -detailed-exitcode
   
   # Fix drift
   terraform apply -refresh-only
   ```

#### Expected Outcomes
- ✅ Successfully backup and restore state
- ✅ Import existing resources into state
- ✅ Detect and resolve state drift

### Exercise 5: Complete VPC/EC2 Infrastructure (45 minutes)

#### Objective
Build a complete infrastructure demonstrating all state management concepts.

#### Tasks

1. **Deploy Complete Infrastructure**
   ```bash
   cd examples/vpc-ec2-demo
   
   # Review configuration
   cat main.tf
   
   # Initialize and deploy
   terraform init
   terraform plan
   terraform apply
   ```

2. **State Analysis**
   ```bash
   # Analyze state structure
   terraform state list
   
   # Show resource dependencies
   terraform show -json | jq '.values.root_module.resources[] | select(.address=="aws_instance.web") | .depends_on'
   
   # Generate dependency graph
   terraform graph | dot -Tpng > infrastructure-graph.png
   ```

3. **State Operations on Complex Infrastructure**
   ```bash
   # Move resources between modules (if applicable)
   terraform state mv aws_security_group.web module.security.aws_security_group.web
   
   # Remove and re-import resources
   terraform state rm aws_route_table_association.public
   terraform import aws_route_table_association.public subnet-xxx/rtb-xxx
   ```

#### Expected Outcomes
- ✅ Deploy complex multi-resource infrastructure
- ✅ Understand resource dependencies in state
- ✅ Perform advanced state operations

## 🔍 Troubleshooting Scenarios

### Scenario 1: Corrupted State File
```bash
# Simulate corruption (DON'T do this in production!)
echo '{"invalid": "json"}' > corrupted-state.json
terraform state push corrupted-state.json

# Recovery steps
terraform state pull > current-state.json
# Fix the JSON manually or restore from backup
terraform state push fixed-state.json
```

### Scenario 2: Lost State File
```bash
# If state is lost, rebuild from existing infrastructure
terraform import aws_vpc.main vpc-xxxxxxxxx
terraform import aws_subnet.public subnet-xxxxxxxxx
terraform import aws_instance.web i-xxxxxxxxx
# Continue for all resources...
```

### Scenario 3: State Lock Issues
```bash
# Check for stuck locks
aws dynamodb scan --table-name terraform-state-locks

# Force unlock if necessary
terraform force-unlock <LOCK_ID>
```

## 📊 Lab Validation

### Validation Checklist

#### Local State (Exercise 1)
- [ ] State file created and contains resources
- [ ] Successfully performed state list/show operations
- [ ] Completed state rm and import operations
- [ ] State file reflects all changes

#### Remote State (Exercise 2)
- [ ] S3 bucket created with proper configuration
- [ ] DynamoDB table created for locking
- [ ] Successfully migrated from local to remote state
- [ ] No local state files remain
- [ ] State accessible via S3

#### State Locking (Exercise 3)
- [ ] Observed automatic lock creation
- [ ] Experienced lock conflict resolution
- [ ] Successfully used force-unlock when needed

#### Advanced Operations (Exercise 4)
- [ ] Created and verified state backups
- [ ] Successfully imported external resources
- [ ] Detected and resolved state drift

#### Complete Infrastructure (Exercise 5)
- [ ] Deployed multi-resource infrastructure
- [ ] Analyzed resource dependencies
- [ ] Performed complex state operations

## 🎯 Success Criteria

By the end of this lab, you should be able to:

1. **Explain State Fundamentals**
   - Describe what Terraform state is and why it's needed
   - Identify components of a state file
   - Understand local vs remote state trade-offs

2. **Configure Remote Backends**
   - Set up S3 backend with proper security
   - Configure DynamoDB for state locking
   - Migrate between different backend types

3. **Perform State Operations**
   - List, show, and inspect state resources
   - Remove and import resources safely
   - Backup and restore state files

4. **Troubleshoot State Issues**
   - Detect and resolve state drift
   - Handle corrupted or lost state files
   - Manage state locks and conflicts

5. **Implement Best Practices**
   - Use remote state for team collaboration
   - Enable encryption and access controls
   - Maintain proper backup strategies

## 🧹 Cleanup Instructions

### Clean Up Lab Resources
```bash
# Destroy main infrastructure
terraform destroy

# Clean up backend resources (optional)
cd examples/remote-state
terraform destroy

# Remove any local files
rm -f *.json *.png terraform.tfstate*
```

## 📝 Lab Report Template

Document your lab experience:

```markdown
# Terraform State Management Lab Report

## Exercise 1: Local State
- Challenges faced:
- Key learnings:
- State file observations:

## Exercise 2: Remote State
- Backend setup experience:
- Migration process:
- Benefits observed:

## Exercise 3: State Locking
- Locking behavior observed:
- Conflict resolution:

## Exercise 4: Advanced Operations
- Most useful state command:
- Troubleshooting experience:

## Exercise 5: Complete Infrastructure
- Complexity management:
- Dependency insights:

## Overall Takeaways
- Most important concept learned:
- Areas for further study:
- Real-world applications:
```

## 🎓 Next Steps

After completing this lab:
1. Practice with your own infrastructure projects
2. Implement remote state in team environments
3. Explore Terraform workspaces
4. Study advanced backend configurations
5. Learn about state encryption and security hardening