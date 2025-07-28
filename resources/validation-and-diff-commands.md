# Terraform Validation and Diff Commands Guide
## Comprehensive Command Reference for Testing and Comparing Infrastructure

---

## Overview

This guide provides detailed commands for validating Terraform configurations, comparing changes, and testing infrastructure modifications. These commands are essential for safe infrastructure management and debugging.

---

## Basic Validation Commands

### Configuration Validation

```bash
# Validate Terraform configuration syntax
terraform validate

# Validate with detailed output
terraform validate -json

# Validate specific directory
terraform validate /path/to/terraform/config

# Validate and check for unused variables
terraform validate -check-variables=false
```

**Expected Output (Success):**
```
Success! The configuration is valid.
```

**Expected Output (Error):**
```
Error: Invalid resource type

  on main.tf line 15, in resource "aws_instance_invalid" "web":
  15: resource "aws_instance_invalid" "web" {

The provider hashicorp/aws does not support resource type "aws_instance_invalid".
```

### Format Validation

```bash
# Check if files are properly formatted
terraform fmt -check

# Format files and show what was changed
terraform fmt -diff

# Format files recursively
terraform fmt -recursive

# Format specific file
terraform fmt main.tf

# Format and write changes
terraform fmt -write=true
```

**Expected Output (fmt -check):**
```
main.tf
variables.tf
```

**Expected Output (fmt -diff):**
```
--- old/main.tf
+++ new/main.tf
@@ -1,4 +1,4 @@
 resource "aws_instance" "web" {
-  ami           = "ami-12345"
+  ami           = "ami-12345"
   instance_type = "t2.micro"
 }
```

---

## Plan and Diff Commands

### Basic Plan Commands

```bash
# Generate execution plan
terraform plan

# Plan with specific variable file
terraform plan -var-file="dev.tfvars"

# Plan with command line variables
terraform plan -var="instance_type=t3.small" -var="region=us-west-2"

# Plan and save to file
terraform plan -out=tfplan

# Plan with detailed output
terraform plan -detailed-exitcode

# Plan for destroy
terraform plan -destroy
```

### Advanced Plan Options

```bash
# Plan with specific target resource
terraform plan -target=aws_instance.web

# Plan with multiple targets
terraform plan -target=aws_instance.web -target=aws_security_group.web

# Plan with refresh disabled
terraform plan -refresh=false

# Plan with parallelism control
terraform plan -parallelism=5

# Plan with lock timeout
terraform plan -lock-timeout=60s
```

### Plan Output Analysis

```bash
# Save plan in JSON format
terraform plan -out=tfplan
terraform show -json tfplan > plan.json

# Show human-readable plan from file
terraform show tfplan

# Show specific resource from plan
terraform show 'aws_instance.web'
```

---

## Environment Comparison Commands

### Compare Different Environments

```bash
# Compare dev vs staging configurations
echo "=== DEV PLAN ==="
terraform plan -var-file="environments/dev.tfvars"

echo "=== STAGING PLAN ==="
terraform plan -var-file="environments/staging.tfvars"

echo "=== PROD PLAN ==="
terraform plan -var-file="environments/prod.tfvars"
```

### Side-by-Side Environment Comparison

```bash
# Create plans for different environments
terraform plan -var-file="dev.tfvars" -out=dev.tfplan
terraform plan -var-file="staging.tfvars" -out=staging.tfplan
terraform plan -var-file="prod.tfvars" -out=prod.tfplan

# Show plans side by side
echo "=== DEV RESOURCES ==="
terraform show dev.tfplan | grep "# aws_"

echo "=== STAGING RESOURCES ==="
terraform show staging.tfplan | grep "# aws_"

echo "=== PROD RESOURCES ==="
terraform show prod.tfplan | grep "# aws_"
```

### Detailed Environment Diff

```bash
# Generate detailed comparison script
cat > compare_environments.sh << 'EOF'
#!/bin/bash

echo "Comparing Terraform environments..."

# Function to extract resource counts
count_resources() {
    local plan_file=$1
    echo "Resource counts for $plan_file:"
    terraform show "$plan_file" | grep -E "^  # aws_" | cut -d' ' -f3 | sort | uniq -c
    echo ""
}

# Generate plans
terraform plan -var-file="dev.tfvars" -out=dev.tfplan > /dev/null
terraform plan -var-file="staging.tfvars" -out=staging.tfplan > /dev/null
terraform plan -var-file="prod.tfvars" -out=prod.tfplan > /dev/null

# Compare resource counts
count_resources "dev.tfplan"
count_resources "staging.tfplan"
count_resources "prod.tfplan"

# Compare specific resources
echo "Instance types comparison:"
echo "DEV:"
terraform show dev.tfplan | grep "instance_type" | head -5
echo "STAGING:"
terraform show staging.tfplan | grep "instance_type" | head -5
echo "PROD:"
terraform show prod.tfplan | grep "instance_type" | head -5

# Cleanup
rm -f *.tfplan
EOF

chmod +x compare_environments.sh
./compare_environments.sh
```

---

## State Validation and Comparison

### State File Validation

```bash
# List all resources in state
terraform state list

# Show specific resource state
terraform state show aws_instance.web

# Show all state information
terraform show

# Validate state consistency
terraform plan -refresh-only

# Check for state drift
terraform plan -detailed-exitcode
echo "Exit code: $?"
# Exit codes: 0=no changes, 1=error, 2=changes present
```

### State Comparison Commands

```bash
# Compare state with actual infrastructure
terraform refresh
terraform plan

# Show state in JSON format
terraform show -json > current_state.json

# Compare state files (if you have backups)
terraform state pull > current_state.json
# Compare with previous backup
diff previous_state.json current_state.json
```

### Advanced State Analysis

```bash
# Create state analysis script
cat > analyze_state.sh << 'EOF'
#!/bin/bash

echo "=== TERRAFORM STATE ANALYSIS ==="
echo ""

echo "Total resources in state:"
terraform state list | wc -l

echo ""
echo "Resource types breakdown:"
terraform state list | cut -d'.' -f1 | sort | uniq -c | sort -nr

echo ""
echo "Resources by name pattern:"
terraform state list | grep -E "(web|app|db)" | sort

echo ""
echo "Checking for drift..."
terraform plan -detailed-exitcode > /dev/null
case $? in
    0) echo "✅ No drift detected" ;;
    1) echo "❌ Error occurred" ;;
    2) echo "⚠️  Drift detected - run 'terraform plan' for details" ;;
esac

echo ""
echo "State file information:"
ls -la terraform.tfstate* 2>/dev/null || echo "No local state files found"
EOF

chmod +x analyze_state.sh
./analyze_state.sh
```

---

## Variable and Expression Testing

### Terraform Console Commands

```bash
# Start interactive console
terraform console

# Test expressions in console
terraform console << 'EOF'
# Test variable access
var.instance_type

# Test conditional expressions
var.environment == "prod" ? "t3.large" : "t2.micro"

# Test functions
length(var.allowed_ports)
upper(var.environment)

# Test complex expressions
[for i in range(3) : "instance-${i + 1}"]

# Test map access
var.instance_types["prod"]

# Test lookup function
lookup(var.region_amis, "us-east-1", "default")
EOF
```

### Variable Validation Testing

```bash
# Test variable validation with invalid values
echo "Testing variable validation..."

# Test invalid instance type
terraform plan -var="instance_type=invalid-type" 2>&1 | grep -A5 "Error:"

# Test invalid environment
terraform plan -var="environment=invalid-env" 2>&1 | grep -A5 "Error:"

# Test invalid instance count
terraform plan -var="instance_count=15" 2>&1 | grep -A5 "Error:"

echo "Validation tests completed."
```

### Expression Testing Script

```bash
# Create expression testing script
cat > test_expressions.sh << 'EOF'
#!/bin/bash

echo "=== TERRAFORM EXPRESSION TESTING ==="

# Test basic expressions
echo "Testing basic expressions:"
terraform console << 'CONSOLE_EOF'
# String operations
upper("hello")
lower("WORLD")
title("terraform rocks")

# Number operations
max(1, 2, 3)
min(10, 5, 8)

# List operations
length(["a", "b", "c"])
join(",", ["web", "app", "db"])

# Conditional expressions
true ? "yes" : "no"
false ? "yes" : "no"
CONSOLE_EOF

echo ""
echo "Testing with actual variables:"
terraform console << 'CONSOLE_EOF'
# Variable access
var.instance_name
var.environment
var.instance_count

# Complex expressions with variables
"${var.instance_name}-${var.environment}"
var.environment == "prod" ? 5 : 2
[for i in range(var.instance_count) : "instance-${i + 1}"]
CONSOLE_EOF
EOF

chmod +x test_expressions.sh
./test_expressions.sh
```

---

## Configuration Comparison Tools

### File Comparison Commands

```bash
# Compare Terraform files between environments
diff environments/dev.tfvars environments/prod.tfvars

# Compare with context
diff -u environments/dev.tfvars environments/prod.tfvars

# Compare directories
diff -r environments/dev/ environments/prod/

# Compare with color output (if available)
colordiff environments/dev.tfvars environments/prod.tfvars
```

### Advanced Configuration Analysis

```bash
# Create configuration analysis script
cat > analyze_config.sh << 'EOF'
#!/bin/bash

echo "=== TERRAFORM CONFIGURATION ANALYSIS ==="

echo ""
echo "File structure:"
find . -name "*.tf" -o -name "*.tfvars" | sort

echo ""
echo "Resource types defined:"
grep -h "^resource" *.tf | cut -d'"' -f2 | sort | uniq -c

echo ""
echo "Variables defined:"
grep -h "^variable" variables.tf | cut -d'"' -f2 | sort

echo ""
echo "Outputs defined:"
grep -h "^output" outputs.tf 2>/dev/null | cut -d'"' -f2 | sort

echo ""
echo "Data sources used:"
grep -h "^data" *.tf | cut -d'"' -f2,4 | sort | uniq

echo ""
echo "Modules used:"
grep -h "^module" *.tf | cut -d'"' -f2 | sort

echo ""
echo "Configuration validation:"
terraform validate && echo "✅ Configuration is valid" || echo "❌ Configuration has errors"
EOF

chmod +x analyze_config.sh
./analyze_config.sh
```

---

## Debugging and Troubleshooting Commands

### Debug Mode Commands

```bash
# Enable debug logging
export TF_LOG=DEBUG
terraform plan

# Enable trace logging (most verbose)
export TF_LOG=TRACE
terraform apply

# Log to file
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log
terraform plan

# Disable logging
unset TF_LOG
unset TF_LOG_PATH
```

### Provider Debug Commands

```bash
# Debug specific provider
export TF_LOG_PROVIDER=DEBUG
terraform plan

# Debug core Terraform
export TF_LOG_CORE=DEBUG
terraform plan
```

### Comprehensive Debug Script

```bash
# Create comprehensive debug script
cat > debug_terraform.sh << 'EOF'
#!/bin/bash

echo "=== TERRAFORM DEBUG INFORMATION ==="

echo ""
echo "Terraform version:"
terraform version

echo ""
echo "Current working directory:"
pwd

echo ""
echo "Terraform files present:"
ls -la *.tf *.tfvars 2>/dev/null

echo ""
echo "Terraform initialization status:"
if [ -d ".terraform" ]; then
    echo "✅ Terraform initialized"
    echo "Provider versions:"
    cat .terraform.lock.hcl | grep -A2 "provider"
else
    echo "❌ Terraform not initialized - run 'terraform init'"
fi

echo ""
echo "State file status:"
if [ -f "terraform.tfstate" ]; then
    echo "✅ Local state file exists"
    echo "Resources in state: $(terraform state list 2>/dev/null | wc -l)"
else
    echo "ℹ️  No local state file (may be using remote state)"
fi

echo ""
echo "Configuration validation:"
terraform validate 2>&1

echo ""
echo "Variable validation test:"
terraform plan -input=false > /dev/null 2>&1
case $? in
    0) echo "✅ Variables are properly configured" ;;
    1) echo "❌ Variable configuration issues detected" ;;
esac

echo ""
echo "AWS credentials status:"
aws sts get-caller-identity > /dev/null 2>&1 && echo "✅ AWS credentials configured" || echo "❌ AWS credentials not configured"

echo ""
echo "Recent Terraform operations:"
ls -la terraform.tfstate* .terraform.lock.hcl 2>/dev/null | head -5
EOF

chmod +x debug_terraform.sh
./debug_terraform.sh
```

---

## Performance and Resource Analysis

### Resource Analysis Commands

```bash
# Analyze resource dependencies
terraform graph | dot -Tpng > graph.png

# Count resources by type
terraform state list | cut -d'.' -f1 | sort | uniq -c

# Find large resources
terraform show -json | jq '.values.root_module.resources[] | select(.type == "aws_instance") | {name: .name, type: .type, values: .values.instance_type}'

# Analyze plan performance
time terraform plan -out=tfplan
```

### Cost Analysis Preparation

```bash
# Extract resource information for cost analysis
terraform show -json > infrastructure.json

# Create resource summary
cat > resource_summary.sh << 'EOF'
#!/bin/bash

echo "=== RESOURCE COST ANALYSIS PREPARATION ==="

echo ""
echo "EC2 Instances:"
terraform state list | grep aws_instance | while read resource; do
    echo -n "$resource: "
    terraform state show "$resource" | grep instance_type | awk '{print $3}' | tr -d '"'
done

echo ""
echo "RDS Instances:"
terraform state list | grep aws_db_instance | while read resource; do
    echo -n "$resource: "
    terraform state show "$resource" | grep instance_class | awk '{print $3}' | tr -d '"'
done

echo ""
echo "Load Balancers:"
terraform state list | grep aws_lb

echo ""
echo "S3 Buckets:"
terraform state list | grep aws_s3_bucket
EOF

chmod +x resource_summary.sh
./resource_summary.sh
```

---

## Automated Testing Scripts

### Complete Validation Pipeline

```bash
# Create comprehensive validation pipeline
cat > validate_pipeline.sh << 'EOF'
#!/bin/bash

set -e  # Exit on any error

echo "🚀 Starting Terraform Validation Pipeline"
echo "========================================"

# Step 1: Format check
echo ""
echo "📝 Step 1: Checking code formatting..."
if terraform fmt -check -recursive; then
    echo "✅ Code formatting is correct"
else
    echo "❌ Code formatting issues found. Run 'terraform fmt -recursive' to fix."
    exit 1
fi

# Step 2: Configuration validation
echo ""
echo "🔍 Step 2: Validating configuration..."
if terraform validate; then
    echo "✅ Configuration is valid"
else
    echo "❌ Configuration validation failed"
    exit 1
fi

# Step 3: Security check (if tfsec is installed)
echo ""
echo "🔒 Step 3: Security scanning..."
if command -v tfsec &> /dev/null; then
    tfsec .
else
    echo "ℹ️  tfsec not installed, skipping security scan"
fi

# Step 4: Plan validation for each environment
echo ""
echo "📋 Step 4: Validating plans for all environments..."

for env in dev staging prod; do
    if [ -f "environments/${env}.tfvars" ]; then
        echo "  Testing $env environment..."
        if terraform plan -var-file="environments/${env}.tfvars" -out="${env}.tfplan" > /dev/null; then
            echo "  ✅ $env plan successful"
            rm -f "${env}.tfplan"
        else
            echo "  ❌ $env plan failed"
            exit 1
        fi
    fi
done

# Step 5: Variable validation
echo ""
echo "🔧 Step 5: Testing variable validation..."
test_vars=(
    "instance_type=invalid-type"
    "environment=invalid-env"
    "instance_count=15"
)

for test_var in "${test_vars[@]}"; do
    echo "  Testing invalid variable: $test_var"
    if terraform plan -var="$test_var" > /dev/null 2>&1; then
        echo "  ❌ Variable validation failed for: $test_var"
        exit 1
    else
        echo "  ✅ Variable validation working for: $test_var"
    fi
done

echo ""
echo "🎉 All validation checks passed!"
echo "✅ Code is ready for deployment"
EOF

chmod +x validate_pipeline.sh
./validate_pipeline.sh
```

---

## Quick Reference Commands

### Daily Validation Workflow

```bash
# Quick validation sequence
terraform fmt -check && \
terraform validate && \
terraform plan -out=tfplan && \
echo "✅ All checks passed"

# Quick environment comparison
for env in dev staging prod; do
    echo "=== $env ==="
    terraform plan -var-file="$env.tfvars" | grep "Plan:"
done

# Quick state health check
terraform plan -detailed-exitcode > /dev/null
echo "State status: $([[ $? -eq 0 ]] && echo "✅ Clean" || echo "⚠️  Drift detected")"
```

### Emergency Debug Commands

```bash
# When things go wrong
export TF_LOG=DEBUG
terraform plan 2>&1 | tee debug.log
terraform validate -json | jq '.diagnostics'
terraform state list | head -10
aws sts get-caller-identity
```

---

## Summary

This comprehensive guide provides all the validation and diff commands needed for:

- **Configuration validation** and syntax checking
- **Environment comparison** and analysis
- **State management** and drift detection
- **Variable testing** and expression validation
- **Debug information** gathering
- **Automated testing** pipelines
- **Performance analysis** and optimization

Use these commands throughout your Terraform development workflow to ensure reliable, consistent infrastructure deployments.