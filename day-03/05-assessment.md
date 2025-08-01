# Day 03: Terraform State Management - Assessment

## 📋 Assessment Overview
This assessment evaluates your understanding of Terraform state management concepts, remote backends, state operations, and best practices.

**Time Limit:** 60 minutes  
**Total Points:** 100 points  
**Passing Score:** 70 points

---

## Section A: Multiple Choice Questions (40 points)

### Question 1 (4 points)
What is the primary purpose of Terraform state?

a) To store Terraform configuration files in a centralized location for team access
b) To map configuration resources to real-world infrastructure and track metadata
c) To provide backup copies of infrastructure in case of accidental deletion
d) To store sensitive variables and credentials securely for infrastructure deployment

**Answer: b**

### Question 2 (4 points)
Which command allows you to remove a resource from Terraform state without destroying the actual infrastructure?

a) `terraform destroy -target=<resource>` to selectively remove specific infrastructure resources
b) `terraform state rm <resource>` to remove resource from state file only
c) `terraform delete <resource>` to remove resource from both state and infrastructure
d) `terraform state delete <resource>` to permanently delete resource from all locations

**Answer: b**

### Question 3 (4 points)
What is the main advantage of using remote state backends over local state?

a) Remote backends provide faster execution times for all terraform operations
b) Remote backends automatically optimize infrastructure costs and resource utilization
c) Remote backends enable team collaboration, locking, and centralized state management
d) Remote backends eliminate the need for terraform configuration files entirely

**Answer: c**

### Question 4 (4 points)
Which AWS services are commonly used together for Terraform remote state backend?

a) EC2 and EBS for compute-based state storage and backup solutions
b) S3 and DynamoDB for state storage and locking mechanism implementation
c) Lambda and API Gateway for serverless state management and access control
d) RDS and ElastiCache for database-driven state storage and caching performance

**Answer: b**

### Question 5 (4 points)
What happens when you run `terraform import aws_instance.web i-1234567890abcdef0`?

a) Creates a new EC2 instance with the specified ID in AWS infrastructure
b) Downloads the instance configuration from AWS and creates terraform configuration files
c) Maps the existing AWS instance to the terraform resource in state file
d) Migrates the instance from one AWS account to another using terraform

**Answer: c**

### Question 6 (4 points)
How does Terraform state locking prevent issues in team environments?

a) By encrypting all state files with team-specific keys for security
b) By preventing concurrent modifications that could corrupt the state file
c) By automatically merging conflicting changes from multiple team members
d) By creating separate state files for each team member's changes

**Answer: b**

### Question 7 (4 points)
What is the purpose of the `serial` field in a Terraform state file?

a) To store the unique identifier for the terraform configuration version
b) To track the incremental version number of state file changes
c) To identify the specific terraform binary version used for deployment
d) To maintain the chronological order of resource creation timestamps

**Answer: b**

### Question 8 (4 points)
Which command would you use to update the state file with the current infrastructure without making changes?

a) `terraform refresh` to synchronize state with actual infrastructure resources
b) `terraform update` to fetch latest resource information from cloud provider
c) `terraform sync` to align state file with current infrastructure configuration
d) `terraform validate` to check state consistency against actual resources

**Answer: a**

### Question 9 (4 points)
What is the recommended approach for handling sensitive data in Terraform state files?

a) Store state files locally with restricted file system permissions only
b) Use environment variables exclusively and avoid storing sensitive data permanently
c) Enable state encryption and use secure remote backend storage solutions
d) Manually edit state files to remove sensitive information after deployment

**Answer: c**

### Question 10 (4 points)
When migrating from local to remote state, which command is used?

a) `terraform init -migrate-state` to transfer existing state to remote backend
b) `terraform state push` to upload local state file to remote location
c) `terraform backend migrate` to move state between different storage systems
d) `terraform remote init` to initialize remote backend with existing state

**Answer: a**

---

## Section B: Short Answer Questions (30 points)

### Question 11 (10 points)
Explain the difference between local and remote state in Terraform. List three advantages of using remote state over local state.

**Sample Answer:**
Local state stores the terraform.tfstate file on the local machine where Terraform is executed, while remote state stores the state file in a remote backend like S3, Azure Storage, or Terraform Cloud.

Three advantages of remote state:
1. **Team Collaboration** - Multiple team members can access and work with the same state file
2. **State Locking** - Prevents concurrent modifications that could corrupt the state file
3. **Security and Encryption** - Remote backends can provide encryption at rest and access controls

### Question 12 (10 points)
Describe the process of importing an existing AWS resource into Terraform state. Include the necessary steps and commands.

**Sample Answer:**
1. **Add resource configuration** to your .tf files matching the existing resource
2. **Run import command**: `terraform import <resource_type>.<resource_name> <resource_id>`
   Example: `terraform import aws_instance.web i-1234567890abcdef0`
3. **Run terraform plan** to see any configuration differences
4. **Update configuration** to match the actual resource attributes
5. **Run terraform plan again** to ensure no changes are needed

### Question 13 (10 points)
What is state drift and how would you detect and resolve it? Provide specific commands.

**Sample Answer:**
State drift occurs when the actual infrastructure differs from what's recorded in the Terraform state file, usually due to manual changes made outside of Terraform.

**Detection:**
- `terraform plan -detailed-exitcode` - Exit code 2 indicates drift
- `terraform plan` - Shows differences between state and actual infrastructure

**Resolution:**
- `terraform apply -refresh-only` - Updates state to match actual infrastructure
- `terraform apply` - Applies configuration to fix infrastructure drift
- Manual correction of infrastructure to match desired state

---

## Section C: Practical Scenarios (30 points)

### Scenario 1 (15 points)
You're working on a team project and need to set up remote state backend using S3 and DynamoDB. Write the Terraform configuration for:

1. S3 bucket with versioning and encryption enabled (8 points)
2. DynamoDB table for state locking (4 points)
3. Backend configuration block (3 points)

**Sample Answer:**

```hcl
# 1. S3 bucket configuration
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-bucket"
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 2. DynamoDB table for locking
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "terraform-state-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# 3. Backend configuration
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}
```

### Scenario 2 (15 points)
Your team member accidentally deleted a critical resource from the Terraform state file, but the actual AWS resource still exists. The resource is an EC2 instance with ID `i-0abcd1234efgh5678`. 

Provide the step-by-step commands to:
1. Add the resource back to the configuration (5 points)
2. Import the existing resource (5 points)
3. Verify the import was successful (5 points)

**Sample Answer:**

```bash
# 1. Add resource configuration to main.tf
cat >> main.tf << EOF
resource "aws_instance" "recovered" {
  ami           = "ami-12345678"  # Use actual AMI ID
  instance_type = "t2.micro"     # Use actual instance type
  
  tags = {
    Name = "Recovered Instance"
  }
}
EOF

# 2. Import the existing resource
terraform import aws_instance.recovered i-0abcd1234efgh5678

# 3. Verify the import was successful
terraform state list | grep aws_instance.recovered
terraform state show aws_instance.recovered
terraform plan  # Should show no changes if configuration matches
```

---

## Section D: Troubleshooting (Bonus - 10 points)

### Bonus Question (10 points)
You encounter the following error when running `terraform plan`:

```
Error: Error acquiring the state lock

Error message: ConditionalCheckFailedException: The conditional request failed
Lock Info:
  ID:        12345678-1234-1234-1234-123456789012
  Path:      my-bucket/terraform.tfstate
  Operation: OperationTypePlan
  Who:       user@example.com
  Version:   1.6.0
  Created:   2024-01-15 10:30:00 UTC
  Info:      
```

Explain what this error means and provide the commands to resolve it safely.

**Sample Answer:**

This error indicates that the Terraform state is locked by another operation. The lock prevents concurrent modifications that could corrupt the state file.

**What it means:**
- Another Terraform operation is currently running or was interrupted
- The lock is held by user@example.com since 10:30:00 UTC
- Lock ID is 12345678-1234-1234-1234-123456789012

**Safe resolution steps:**

1. **First, verify no one is actually running Terraform:**
   ```bash
   # Check with team members if anyone is running Terraform
   # Wait a reasonable time for the operation to complete
   ```

2. **Check the lock age:**
   ```bash
   # If the lock is old (hours/days), it's likely stuck
   aws dynamodb scan --table-name terraform-state-locks
   ```

3. **Force unlock (only if certain no operation is running):**
   ```bash
   terraform force-unlock 12345678-1234-1234-1234-123456789012
   ```

4. **Verify unlock and retry:**
   ```bash
   terraform plan  # Should work now
   ```

---

## 📊 Answer Key Summary

### Section A (Multiple Choice)
1. b  2. b  3. c  4. b  5. c  6. b  7. b  8. a  9. c  10. a

### Section B (Short Answer)
- Detailed explanations provided in sample answers above

### Section C (Practical Scenarios)
- Complete code examples provided above

### Section D (Bonus)
- Troubleshooting steps and commands provided above

---

## 🎯 Scoring Rubric

### Section A: Multiple Choice (40 points)
- 4 points per correct answer
- No partial credit

### Section B: Short Answer (30 points)
- **Excellent (9-10 points):** Complete, accurate answer with all key points
- **Good (7-8 points):** Mostly correct with minor omissions
- **Satisfactory (5-6 points):** Basic understanding shown, some errors
- **Needs Improvement (0-4 points):** Significant errors or incomplete

### Section C: Practical Scenarios (30 points)
- **Excellent (13-15 points):** Correct, complete, and well-structured code
- **Good (10-12 points):** Mostly correct with minor syntax issues
- **Satisfactory (7-9 points):** Basic functionality with some errors
- **Needs Improvement (0-6 points):** Major errors or incomplete solution

### Section D: Bonus (10 points)
- **Full Credit (8-10 points):** Complete understanding and correct resolution
- **Partial Credit (4-7 points):** Good understanding with minor gaps
- **Minimal Credit (1-3 points):** Basic understanding shown
- **No Credit (0 points):** Incorrect or no answer

---

## 📈 Performance Levels

- **90-100 points:** Expert Level - Ready for advanced Terraform topics
- **80-89 points:** Proficient Level - Strong understanding with minor gaps
- **70-79 points:** Competent Level - Meets minimum requirements
- **60-69 points:** Developing Level - Needs additional study and practice
- **Below 60 points:** Novice Level - Requires significant review and practice

---

## 📚 Study Resources for Review

If you scored below 70 points, review these materials:
- Day 03 Lecture Notes (01-lecture-notes.md)
- State Operations Guide (02-state-operations.md)
- Remote Backends Guide (03-remote-backends.md)
- Hands-On Lab exercises (04-hands-on-lab.md)
- Official Terraform documentation on state management