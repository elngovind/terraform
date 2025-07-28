# Day 2 Lecture Notes: Advanced Terraform Concepts
## HCL Deep Dive, Variables, Data Types & Dynamic Infrastructure

**Duration:** 120 minutes | **Prerequisites:** Day 1 completed

---

## Learning Objectives

- Master HCL syntax: blocks, arguments, and expressions
- Understand variables, outputs, and data types
- Implement dynamic expressions and loops
- Use .tfvars files and variable overriding
- Build parametrized infrastructure

---

## Quick Recap - Day 1 Summary

### What We Covered Previously

1. **Infrastructure in DevOps**
   - Infrastructure includes servers, storage, networking, IAM, monitoring
   - Analogy: If application is your house, infrastructure is the land, plumbing, wiring

2. **Why IaC Matters**
   - Manual setup is slow, error-prone, inconsistent
   - IaC makes infrastructure repeatable, testable, version-controlled
   - Analogy: Manual setup is like cooking from memory, IaC is like using a recipe

3. **IaC Approaches**
   - **Declarative** (Terraform): Define what you want
   - **Imperative** (Ansible): Define how to do it step-by-step

4. **Why Terraform**
   - Multi-cloud support (AWS, Azure, GCP)
   - HCL (HashiCorp Configuration Language)
   - State management
   - Rich ecosystem of providers and modules

5. **Terraform Architecture**
   - **Terraform Core:** Parses .tf files and builds plans
   - **Providers:** Plugins that communicate with platforms
   - **State File:** Tracks current infrastructure state
   - **Configuration Files:** Define resources (main.tf, variables.tf)

---

## 1. HCL Basics - Blocks, Arguments, and Expressions (25 minutes)

### What is HCL?

HCL (HashiCorp Configuration Language) is a declarative, human-readable configuration language used by Terraform to define infrastructure.

**Analogy:** HCL is like a recipe book
- Each block is a recipe (like baking a cake or setting up EC2)
- Arguments are ingredients and settings (sugar = 1 cup)
- Expressions are calculations or references (bake_time = base_time * 2)

### Basic HCL Anatomy

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}
```

### 1.1 Blocks

A block is a container for configuration with a type, labels, and body.

**Syntax:**
```hcl
block_type "label1" "label2" {
  argument = value
}
```

**Example:**
```hcl
resource "aws_instance" "web" {
  # Configuration goes here
}
```

- `resource` = block type
- `"aws_instance"` = first label (resource type)
- `"web"` = second label (resource name)

**Common Block Types:**
- `resource` - Define cloud resources
- `provider` - Configure cloud provider
- `variable` - Define input parameters
- `output` - Display values after apply
- `module` - Reuse configurations

### 1.2 Arguments

Arguments are key-value pairs inside blocks that define configuration.

**Syntax:**
```hcl
key = value
```

**Examples:**
```hcl
instance_type = "t2.micro"
ami           = "ami-12345678"
count         = 3
```

**Important Notes:**
- Arguments are order-independent
- Values can be strings, numbers, booleans, lists, maps, or expressions

### 1.3 Expressions

Expressions are anything Terraform evaluates to produce a value.

**Examples:**
```hcl
# Variable reference
name = var.instance_name

# String interpolation
name = "web-${var.environment}"

# Function calls
tags = {
  Name = "web-${upper(var.environment)}"
}

# Conditional expression
instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"
```

---

## 2. Dynamic Expressions in Terraform (20 minutes)

### 2.1 Functions

Terraform provides built-in functions for transforming and calculating values.

**Common Functions:**

| Category | Examples |
|----------|----------|
| String | `upper()`, `lower()`, `replace()`, `trim()` |
| Numeric | `max()`, `min()`, `floor()`, `ceil()` |
| Collections | `length()`, `join()`, `lookup()`, `merge()` |
| Encoding | `base64encode()`, `base64decode()` |
| Date/Time | `timestamp()`, `formatdate()` |

**Examples:**
```hcl
# Count resources dynamically
count = length(var.subnet_ids)

# Transform strings
name = upper(var.environment)

# Join lists
availability_zones = join(",", var.az_list)
```

### 2.2 Conditional Expressions

Terraform supports ternary-style conditions:

**Syntax:**
```hcl
<condition> ? <true_value> : <false_value>
```

**Examples:**
```hcl
# Environment-based instance sizing
instance_type = var.env == "prod" ? "t3.medium" : "t3.micro"

# Enable features conditionally
monitoring_enabled = var.env == "prod" ? true : false

# Resource count based on environment
instance_count = var.env == "prod" ? 3 : 1
```

### 2.3 Loops

Terraform provides two main loop constructs: `count` and `for_each`.

#### Using count

Use `count` for N identical copies of a resource.

```hcl
resource "aws_instance" "web" {
  count         = 3
  ami           = "ami-123456"
  instance_type = "t2.micro"
  
  tags = {
    Name = "Web-${count.index}"
  }
}
```

- Creates 3 EC2 instances
- `count.index` provides 0-based index (0, 1, 2)

#### Using for_each

Use `for_each` for looping over maps or sets with specific keys/values.

```hcl
resource "aws_s3_bucket" "buckets" {
  for_each = toset(["app1", "app2", "app3"])
  bucket   = "my-bucket-${each.value}"
}
```

- `each.value` gives current item in the set
- `each.key` gives the key (same as value for sets)

**When to Use:**
- **count:** Identical resources, need index access
- **for_each:** Named/keyed resources, looping over maps/sets

---

## 3. Terraform Variables and Outputs (25 minutes)

### 3.1 Input Variables

Input variables make Terraform configurations flexible and reusable.

**Basic Syntax:**
```hcl
variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}
```

**Variable Types:**
```hcl
# String
variable "region" {
  type = string
}

# Number
variable "instance_count" {
  type = number
}

# Boolean
variable "enable_monitoring" {
  type = bool
}

# List
variable "availability_zones" {
  type = list(string)
}

# Map
variable "instance_types" {
  type = map(string)
}
```

**Using Variables:**
```hcl
provider "aws" {
  region = var.region
}

resource "aws_instance" "web" {
  count         = var.instance_count
  instance_type = var.instance_types[var.environment]
}
```

### 3.2 Variable Validation

Add validation rules to ensure correct input values:

```hcl
variable "environment" {
  type        = string
  description = "Environment name"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

### 3.3 Output Variables

Outputs expose useful information after Terraform applies configuration.

**Syntax:**
```hcl
output "instance_ip" {
  description = "Public IP of EC2 instance"
  value       = aws_instance.web.public_ip
  sensitive   = false
}
```

**Use Cases:**
- Debugging and verification
- Passing values to other modules
- Integration with CI/CD pipelines

---

## 4. Terraform Data Types (15 minutes)

### 4.1 Primitive Types

| Type | Description | Example |
|------|-------------|---------|
| `string` | Text values | `"us-east-1"` |
| `number` | Numeric values | `5`, `2.5` |
| `bool` | Boolean values | `true`, `false` |

### 4.2 Collection Types

| Type | Description | Example |
|------|-------------|---------|
| `list` | Ordered sequence | `["a", "b", "c"]` |
| `map` | Key-value pairs | `{key = "value"}` |
| `set` | Unique values | `["a", "b"]` (no duplicates) |

### 4.3 Structural Types

| Type | Description | Example |
|------|-------------|---------|
| `object` | Named attributes | `{name = string, count = number}` |
| `tuple` | Fixed-length mixed types | `["us-east-1", 3, true]` |

**Complex Example:**
```hcl
variable "server_config" {
  type = object({
    name     = string
    cpu      = number
    is_linux = bool
    tags     = map(string)
  })
  
  default = {
    name     = "web-server"
    cpu      = 4
    is_linux = true
    tags     = {
      Environment = "dev"
      Owner       = "team"
    }
  }
}
```

---

## 5. Terraform Console - Practical Examples (10 minutes)

Terraform console is an interactive REPL for testing expressions.

**Usage:**
```bash
terraform console
```

**Examples:**

```hcl
# List indexing
> ["dev", "qa", "prod"][1]
"qa"

# Map access
> {dev = "t2.micro", prod = "t3.medium"}["prod"]
"t3.medium"

# Functions
> upper("hello")
"HELLO"

> length(["a", "b", "c"])
3

# Conditional
> "prod" == "dev" ? "large" : "small"
"small"
```

---

## 6. .tfvars Files and Variable Overriding (15 minutes)

### 6.1 Creating .tfvars Files

Separate configuration from code using .tfvars files:

**terraform.tfvars:**
```hcl
region        = "us-west-2"
instance_type = "t3.medium"
environment   = "prod"
```

### 6.2 Using .tfvars Files

```bash
# Explicit file
terraform apply -var-file="prod.tfvars"

# Auto-loading (terraform.tfvars or *.auto.tfvars)
terraform apply
```

### 6.3 Variable Precedence

Terraform follows this order (highest to lowest precedence):

1. CLI `-var` flags
2. CLI `-var-file` flags  
3. Environment variables (`TF_VAR_name`)
4. `terraform.tfvars` or `*.auto.tfvars`
5. Default values in `variables.tf`

**Example:**
```bash
# This overrides all other sources
terraform apply -var="region=eu-central-1"
```

---

## 7. Hands-On Demo: Parametrized EC2 + VPC (10 minutes)

### Project Structure
```
terraform-variables-demo/
├── main.tf              # Resource definitions
├── variables.tf         # Input variables
├── outputs.tf           # Output variables
└── dev.tfvars          # Environment values
```

### Key Concepts Demonstrated

1. **Variable Types:** String, list, map, object
2. **Loops:** `for_each` for subnets and instances
3. **Expressions:** Dynamic tagging and naming
4. **Outputs:** Return useful infrastructure data

**Sample Configuration:**
```hcl
# Create multiple subnets using for_each
resource "aws_subnet" "public" {
  for_each = toset(var.public_subnet_cidrs)
  
  vpc_id     = aws_vpc.main.id
  cidr_block = each.value
  
  tags = {
    Name = "public-subnet-${each.key}"
  }
}

# Create instances from object list
resource "aws_instance" "web" {
  for_each = {
    for i, inst in var.instances :
    inst.name => inst
  }
  
  ami           = var.ami_id
  instance_type = var.instance_type
  
  tags = merge(var.tags, {
    Name = each.key
    Environment = var.env
  })
}
```

---

## Key Takeaways

### Today's Concepts Summary

| Concept | Summary |
|---------|---------|
| **HCL Basics** | Blocks, arguments, expressions - building blocks of infrastructure code |
| **Input Variables** | Make code reusable across regions and environments |
| **Output Variables** | Return useful information like IPs and IDs |
| **Data Types** | Strings, lists, maps, objects - structure your data properly |
| **Dynamic Expressions** | Functions, conditionals, loops for smart infrastructure |
| **Terraform Console** | Interactive testing of expressions and data structures |
| **.tfvars Files** | Clean separation between logic and configuration |

### Best Practices Learned

1. **Use appropriate data types** for variables
2. **Validate inputs** with validation blocks
3. **Separate environments** with .tfvars files
4. **Use for_each** for named resources
5. **Use count** for identical resources
6. **Test expressions** in terraform console
7. **Document variables** with descriptions

---

## Next Session Preview

In the next session, we'll apply these concepts hands-on by:
- Building a complete modular e-commerce infrastructure
- Creating reusable modules
- Implementing environment-specific configurations
- Using advanced Terraform patterns

**Continue to:** [Modular Architecture Guide](02-modular-guide.md)