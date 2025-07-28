# Terraform MCQs - Application Oriented
## Basics to Intermediate Level Assessment

---

### Question 1: Infrastructure Planning (Basic)
You're tasked with deploying a web application that requires an EC2 instance, RDS database, and S3 bucket. What is the BEST first step before writing Terraform code?

A) Start writing resource blocks immediately  
B) Run `terraform init` in an empty directory  
C) Design the architecture and create a project structure with modules  
D) Install the latest version of Terraform  

**Answer: C**  
**Explanation:** Planning the architecture and organizing code into modules ensures maintainable, scalable infrastructure. This follows IaC best practices for production environments.

---

### Question 2: Variable Validation (Intermediate)
In an e-commerce platform deployment, you need to ensure the environment variable only accepts "dev", "staging", or "prod". Which validation block is correct?

A) 
```hcl
validation {
  condition = var.environment == "dev" || "staging" || "prod"
  error_message = "Invalid environment"
}
```

B)
```hcl
validation {
  condition = contains(["dev", "staging", "prod"], var.environment)
  error_message = "Environment must be dev, staging, or prod"
}
```

C)
```hcl
validation {
  condition = var.environment in ["dev", "staging", "prod"]
  error_message = "Invalid environment"
}
```

D)
```hcl
validation {
  condition = regex("dev|staging|prod", var.environment)
  error_message = "Invalid environment"
}
```

**Answer: B**  
**Explanation:** The `contains()` function properly checks if the variable value exists in the allowed list. Option A has incorrect syntax, C uses invalid "in" operator, and D uses regex unnecessarily.

---

### Question 3: Module Dependencies (Intermediate)
You're building a modular e-commerce infrastructure where the database module needs VPC information from the networking module. What's the BEST approach?

A) Hard-code the VPC ID in the database module  
B) Use data sources in the database module to fetch VPC information  
C) Pass VPC outputs from networking module as inputs to database module  
D) Create all resources in a single main.tf file  

**Answer: C**  
**Explanation:** Passing outputs as inputs creates explicit dependencies and makes modules reusable. This is the standard pattern for modular Terraform architecture.

---

### Question 4: State Management (Intermediate)
Your team is working on a production e-commerce platform. A developer accidentally deleted the local terraform.tfstate file. What should you do?

A) Run `terraform import` for each resource individually  
B) Delete all AWS resources and run `terraform apply` again  
C) Restore from remote state backend (S3 + DynamoDB)  
D) Recreate the state file manually  

**Answer: C**  
**Explanation:** Remote state backends provide centralized, versioned state management. This is why production environments should always use remote state storage with locking.

---

### Question 5: Resource Lifecycle (Basic-Intermediate)
In your e-commerce platform, you need to replace the RDS instance but want to create the new one before destroying the old one to minimize downtime. Which lifecycle rule should you use?

A) `prevent_destroy = true`  
B) `ignore_changes = ["engine_version"]`  
C) `create_before_destroy = true`  
D) `replace_triggered_by = [aws_db_instance.old]`  

**Answer: C**  
**Explanation:** `create_before_destroy = true` ensures the new resource is created before the old one is destroyed, minimizing downtime during replacements.

---

### Question 6: Local Values and Functions (Intermediate)
You're deploying infrastructure across multiple environments (dev, staging, prod) with different instance sizes. Which approach demonstrates BEST use of locals and functions?

A)
```hcl
locals {
  instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"
}
```

B)
```hcl
locals {
  env_config = {
    dev  = { instance_type = "t3.micro", min_size = 1 }
    prod = { instance_type = "t3.large", min_size = 3 }
  }
  current_config = local.env_config[var.environment]
}
```

C)
```hcl
variable "instance_types" {
  default = ["t3.micro", "t3.small", "t3.large"]
}
```

D)
```hcl
resource "aws_instance" "web" {
  instance_type = var.environment == "prod" ? "t3.large" : var.environment == "staging" ? "t3.medium" : "t3.micro"
}
```

**Answer: B**  
**Explanation:** Using a map in locals provides clean, scalable configuration management. It's easily extensible for new environments and keeps configuration centralized and readable.

---

## Scoring Guide:
- **6/6:** Expert level - Ready for production Terraform work
- **4-5/6:** Intermediate - Good understanding, minor gaps to fill
- **2-3/6:** Basic - Needs more practice with intermediate concepts
- **0-1/6:** Beginner - Focus on fundamentals first

---

## Key Learning Areas Covered:
✅ Infrastructure planning and modular design  
✅ Variable validation and type constraints  
✅ Module dependencies and data flow  
✅ State management and remote backends  
✅ Resource lifecycle management  
✅ Local values and environment-specific configurations  

---

*These questions are designed to test practical, real-world Terraform knowledge applicable to production environments.*