# Day 2: Advanced Terraform Concepts
## HCL Deep Dive, Variables, Data Types & Dynamic Infrastructure

**Duration:** 3 hours | **Level:** Intermediate | **Prerequisites:** Day 1 completed

---

## Learning Objectives

By the end of Day 2, you will:
- Master HCL syntax: blocks, arguments, and expressions
- Understand variables, outputs, and all Terraform data types
- Implement dynamic expressions with functions, conditionals, and loops
- Use .tfvars files and understand variable precedence
- Build modular infrastructure with reusable components
- Create parametrized, environment-aware infrastructure
- Apply production-ready Terraform patterns

---

## Class Schedule

### Session 1: HCL Deep Dive & Variables (90 minutes)
**File:** [01-lecture-notes.md](01-lecture-notes.md)

**Topics Covered:**
- **Quick Recap** - Day 1 summary and IaC fundamentals
- **HCL Basics** - Blocks, arguments, expressions with practical examples
- **Dynamic Expressions** - Functions, conditionals, loops (count vs for_each)
- **Variables & Outputs** - Input/output variables with validation
- **Data Types** - Primitive, collection, and structural types
- **Terraform Console** - Interactive testing and debugging
- **.tfvars Files** - Environment separation and variable precedence

### Session 2: Modular Architecture (30 minutes)
**File:** [02-modular-guide.md](02-modular-guide.md)
- Module creation patterns and best practices
- Reusable infrastructure components
- Module composition strategies

### Session 3: Hands-On Projects (90 minutes)

#### Part A: Simple Modular Demo (45 minutes)
**File:** [03-simple-modular-demo.md](03-simple-modular-demo.md)

**What You'll Build:**
- **Step-by-step modular project** for beginners
- Simple web application with 3 modules (networking, security, compute)
- Clear module communication and data flow
- Easy-to-understand module structure

#### Part B: Advanced Parametrized Infrastructure (45 minutes)
**File:** [03-hands-on-project.md](03-hands-on-project.md)

**What You'll Build:**
- **Complex parametrized EC2 + VPC Infrastructure**
- Dynamic subnet creation using for_each loops
- Multiple EC2 instances from object lists
- Environment-specific configurations (dev vs prod)
- Conditional resource creation
- Advanced variable validation and data types

### Session 4: Assessment (15 minutes)
**File:** [04-assessment.md](04-assessment.md)
- 6 application-oriented questions covering advanced concepts
- Minimum passing score: 4/6

---

## Learning Path

### Beginner Path (Recommended)
1. **Start with:** [Simple Modular Demo](03-simple-modular-demo.md)
   - Learn basic module concepts
   - Understand module communication
   - Build confidence with simple project

2. **Progress to:** [Advanced Parametrized Project](03-hands-on-project.md)
   - Apply advanced concepts
   - Work with complex data types
   - Implement production patterns

### Advanced Path (For Experienced Users)
1. **Jump to:** [Advanced Parametrized Project](03-hands-on-project.md)
   - Complex infrastructure patterns
   - Advanced Terraform features
   - Production-ready implementations

---

## Prerequisites

### Required Knowledge
- Day 1 concepts mastered
- Basic Terraform workflow (init, plan, apply, destroy)
- AWS fundamentals and CLI configured

### Required Tools
- Terraform >= 1.2
- AWS CLI configured with appropriate permissions
- Text editor with Terraform syntax highlighting

---

## Key Concepts Covered

### HCL Language Features
```hcl
# Blocks, arguments, expressions
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.env == "prod" ? "t3.large" : "t3.micro"
  
  tags = merge(var.common_tags, {
    Name = "web-${count.index}"
  })
}
```

### Variable Types and Validation
```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "server_config" {
  type = object({
    name     = string
    cpu      = number
    is_linux = bool
  })
}
```

### Module Architecture
```hcl
# Simple module usage
module "networking" {
  source = "./modules/networking"
  
  project_name = var.project_name
  vpc_cidr     = "10.0.0.0/16"
}

# Advanced module with complex inputs
module "compute" {
  source = "./modules/compute"
  
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.subnet_ids
  instances  = var.instance_configurations
}
```

### Dynamic Infrastructure Patterns
```hcl
# for_each for named resources
resource "aws_subnet" "public" {
  for_each = toset(var.subnet_cidrs)
  
  vpc_id     = aws_vpc.main.id
  cidr_block = each.value
  
  tags = {
    Name = "subnet-${each.key}"
  }
}

# Conditional resources
resource "aws_cloudwatch_metric_alarm" "cpu" {
  count = var.env == "prod" ? 1 : 0
  # ... configuration
}
```

---

## Hands-On Projects Overview

### Simple Modular Demo
```
Simple Web Application:
├── VPC with public subnet
├── Security group for web access
├── EC2 instance running web server
└── Clean module separation
```

**Features:**
- 3 focused modules (networking, security, compute)
- Clear data flow between modules
- Simple variable usage
- Easy to understand and modify

### Advanced Parametrized Infrastructure
```
Complex Infrastructure Demo:
├── VPC with configurable CIDR
├── Multiple public subnets (for_each loop)
├── EC2 instances from object list
├── Environment-specific configurations
├── Conditional monitoring (prod only)
└── Dynamic security group rules
```

**Features:**
- All Terraform data types in practical use
- Dynamic loops with count and for_each
- Conditional logic for environment-specific resources
- Variable validation with custom rules
- Complex expressions using functions and interpolation
- Environment separation using .tfvars files

---

## Completion Checklist

### Technical Skills
- [ ] HCL syntax mastered (blocks, arguments, expressions)
- [ ] All variable types understood and implemented
- [ ] Dynamic expressions with functions and conditionals
- [ ] Loops implemented (count and for_each)
- [ ] Variable validation rules created
- [ ] .tfvars files for environment separation
- [ ] Terraform console used for testing
- [ ] Modules created and used effectively

### Practical Application
- [ ] Simple modular project completed
- [ ] Advanced parametrized infrastructure built
- [ ] Environment-specific configurations implemented
- [ ] Conditional resources based on environment
- [ ] Advanced outputs with useful information
- [ ] Variable precedence understood and tested
- [ ] Assessment passed (4/6 minimum)
- [ ] Day 2 assignment completed

---

## Real-World Applications

### DevOps Use Cases Covered
- **Multi-environment deployments** (dev, staging, prod)
- **Dynamic resource scaling** based on requirements
- **Conditional feature toggles** (monitoring, backup, etc.)
- **Reusable infrastructure patterns** across projects
- **Environment-specific configurations** without code duplication
- **Advanced tagging strategies** for cost management
- **Infrastructure parameterization** for team collaboration

### Production Patterns Learned
- Variable validation for input safety
- Environment separation best practices
- Dynamic resource creation patterns
- Complex data structure handling
- Advanced Terraform functions usage
- Conditional infrastructure deployment
- Modular architecture design

---

## Next Steps

After completing Day 2:
1. **Complete Assessment** - Validate your understanding
2. **Work on Assignment** - Build a modular blog platform architecture
3. **Practice Concepts** - Apply learned patterns to your own projects
4. **Prepare for Day 3** - Advanced Terraform features (coming soon)

---

## Troubleshooting

### Common Issues
- **Variable validation errors:** Check validation conditions and input values
- **for_each errors:** Ensure you're using sets or maps, not lists directly
- **Type conversion issues:** Use appropriate type conversion functions
- **Module path errors:** Verify module source paths are correct
- **Terraform console errors:** Verify variable references and syntax

### Best Practices Reinforced
- Always validate input variables
- Use descriptive variable names and descriptions
- Separate environment configurations with .tfvars
- Test expressions in terraform console before using
- Use appropriate loop constructs (count vs for_each)
- Document complex expressions and logic
- Start simple, then add complexity

---

## Resources for Continued Learning

### Official Documentation
- [Terraform Language Documentation](https://developer.hashicorp.com/terraform/language)
- [Built-in Functions Reference](https://developer.hashicorp.com/terraform/language/functions)
- [Variable and Type Constraints](https://developer.hashicorp.com/terraform/language/values/variables)
- [Module Development](https://developer.hashicorp.com/terraform/language/modules/develop)

### Advanced Topics to Explore
- Custom validation rules
- Complex data transformations
- Advanced module patterns
- Terraform workspaces
- Remote state management

---

**Ready to master advanced Terraform? Start with [Lecture Notes](01-lecture-notes.md), then choose your learning path!**

*Day 2 transforms you from a Terraform beginner to someone who can build sophisticated, production-ready infrastructure as code.*