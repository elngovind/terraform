# Terraform Day 01 - Basic MCQs
## Fundamentals & Core Concepts

---

### Question 1: Infrastructure as Code Basics
What is the PRIMARY advantage of using Infrastructure as Code (IaC) over manual infrastructure deployment?

A) It's faster to deploy resources manually  
B) Version control, repeatability, and consistency  
C) Manual deployment is more secure  
D) IaC tools are free to use  

**Answer: B**  
**Explanation:** IaC provides version control, repeatability, and consistency - eliminating human errors and enabling infrastructure to be treated like application code.

---

### Question 2: Terraform vs Other IaC Tools
Which statement BEST describes Terraform's advantage over AWS CloudFormation?

A) Terraform only works with AWS  
B) CloudFormation is faster than Terraform  
C) Terraform is cloud-agnostic and works with multiple providers  
D) Terraform doesn't require state management  

**Answer: C**  
**Explanation:** Terraform's key advantage is being cloud-agnostic, supporting 3000+ providers (AWS, Azure, GCP, etc.) while CloudFormation is AWS-specific.

---

### Question 3: HCL Syntax Basics
Which HCL block structure is CORRECT for creating an AWS EC2 instance?

A) 
```hcl
aws_instance "web" {
  resource = "t2.micro"
  ami = "ami-12345"
}
```

B)
```hcl
resource "aws_instance" "web" {
  instance_type = "t2.micro"
  ami = "ami-12345"
}
```

C)
```hcl
instance "aws_instance" "web" {
  type = "t2.micro"
  ami = "ami-12345"
}
```

D)
```hcl
resource aws_instance web {
  instance_type = "t2.micro"
  ami = "ami-12345"
}
```

**Answer: B**  
**Explanation:** Terraform resource syntax is: `resource "provider_resource_type" "local_name" { arguments }`

---

### Question 4: Terraform State
What happens to terraform.tfstate file when you run `terraform apply`?

A) It gets deleted after successful deployment  
B) It tracks the current state of your infrastructure  
C) It only stores configuration, not actual resource information  
D) It's optional and not required for Terraform to work  

**Answer: B**  
**Explanation:** The state file tracks the current state of infrastructure, mapping configuration to real-world resources for future operations.

---

### Question 5: Terraform Workflow
What is the CORRECT sequence of Terraform commands for first-time deployment?

A) `terraform plan` → `terraform apply` → `terraform init`  
B) `terraform apply` → `terraform init` → `terraform plan`  
C) `terraform init` → `terraform plan` → `terraform apply`  
D) `terraform init` → `terraform apply` → `terraform plan`  

**Answer: C**  
**Explanation:** Always start with `terraform init` to initialize providers, then `terraform plan` to preview changes, finally `terraform apply` to deploy.

---

### Question 6: Provider Configuration
In Terraform, what is a "provider"?

A) A company that provides cloud services  
B) A plugin that enables Terraform to interact with APIs  
C) A person who writes Terraform code  
D) A type of Terraform resource  

**Answer: B**  
**Explanation:** Providers are plugins that enable Terraform to interact with cloud providers, SaaS providers, and other APIs.

---

### Question 7: Manual vs Automated Deployment
Your team manually creates 50 EC2 instances for a project. After 6 months, you need identical infrastructure in another region. What's the MAIN challenge?

A) Cost will be higher in the new region  
B) Remembering exact configurations and ensuring consistency  
C) AWS doesn't allow duplicate resources  
D) Manual deployment is always faster  

**Answer: B**  
**Explanation:** Manual processes lack documentation and repeatability, making it difficult to recreate identical infrastructure consistently.

---

## Scoring Guide:
- **7/7:** Excellent grasp of Day 01 fundamentals
- **5-6/7:** Good understanding, minor review needed  
- **3-4/7:** Basic concepts understood, practice more
- **0-2/7:** Review Day 01 lecture materials

---

## Key Day 01 Concepts Covered:
✅ IaC advantages over manual deployment  
✅ Terraform vs other IaC tools  
✅ HCL syntax basics  
✅ Terraform state fundamentals  
✅ Basic Terraform workflow  
✅ Provider concept  
✅ Manual deployment challenges  

---

*These questions cover the core concepts from the 150-minute Day 01 lecture.*