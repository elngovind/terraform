# Day 1 Assignment: Basic Infrastructure Deployment
## Homework Assignment

**Due:** Before Day 2 class | **Estimated Time:** 2 hours

---

## Assignment Overview

Apply Day 1 concepts by creating your own infrastructure deployment. This assignment reinforces the fundamentals learned in class.

---

## Assignment Tasks

### Task 1: Personal Web Server (45 minutes)

Create a Terraform configuration to deploy:
- EC2 instance running a web server
- Security group allowing HTTP and SSH access
- Elastic IP for static public IP

**Requirements:**
- Use variables for instance type and key pair name
- Include proper resource tags
- Output the public IP and DNS name

**Deliverables:**
- `main.tf` - Resource definitions
- `variables.tf` - Variable declarations
- `outputs.tf` - Output values
- `terraform.tfvars` - Variable values

### Task 2: Documentation (30 minutes)

Create a `README.md` file that includes:
- Purpose of the infrastructure
- Prerequisites for deployment
- Step-by-step deployment instructions
- How to access the web server
- Cleanup instructions

### Task 3: State Management (15 minutes)

Answer these questions in a file called `state-questions.md`:
1. What information is stored in the Terraform state file?
2. Why is the state file important?
3. What happens if you lose the state file?
4. How would you share state with a team?

### Task 4: Troubleshooting (30 minutes)

Intentionally break your configuration and document:
- What error occurred
- How you identified the problem
- How you fixed it

Create a file called `troubleshooting-log.md` with your findings.

---

## Bonus Challenges (Optional)

### Bonus 1: Multiple Instances
Modify your configuration to deploy 2 web servers with a load balancer.

### Bonus 2: Data Sources
Use data sources to:
- Find the latest Amazon Linux AMI
- Get availability zones in your region

### Bonus 3: Conditional Resources
Add a variable to conditionally create an Elastic IP.

---

## Submission Guidelines

### File Structure
```
day-01-assignment/
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── state-questions.md
├── troubleshooting-log.md
└── screenshots/
    ├── terraform-plan.png
    ├── terraform-apply.png
    └── web-server-access.png
```

### What to Submit
1. All Terraform configuration files
2. Documentation files
3. Screenshots of successful deployment
4. Evidence of web server accessibility

### Submission Method
- Create a GitHub repository
- Include all files and documentation
- Share the repository link

---

## Evaluation Criteria

### Technical Implementation (60%)
- Configuration syntax is correct
- Resources deploy successfully
- Variables and outputs used properly
- Code follows best practices

### Documentation (25%)
- Clear and comprehensive README
- Accurate deployment instructions
- Proper troubleshooting documentation

### Understanding (15%)
- State management questions answered correctly
- Demonstrates understanding of concepts
- Bonus challenges attempted

---

## Common Mistakes to Avoid

1. **Hardcoded values** - Use variables instead
2. **Missing tags** - Tag all resources appropriately
3. **Security issues** - Don't open unnecessary ports
4. **No cleanup** - Always destroy resources when done
5. **Poor documentation** - Write clear instructions

---

## Getting Help

### Resources
- Day 1 lecture notes and lab materials
- Terraform documentation
- AWS provider documentation

### Support
- Create issues in the course repository
- Ask questions during office hours
- Collaborate with classmates (but submit individual work)

---

## Sample Configuration Structure

```hcl
# variables.tf
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

# main.tf
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  
  tags = {
    Name = "Day1-Assignment-WebServer"
  }
}

# outputs.tf
output "public_ip" {
  description = "Public IP of web server"
  value       = aws_instance.web.public_ip
}
```

---

## Assignment Checklist

- [ ] Task 1: Web server infrastructure created
- [ ] Task 2: Documentation completed
- [ ] Task 3: State management questions answered
- [ ] Task 4: Troubleshooting documented
- [ ] Screenshots captured
- [ ] Repository created and shared
- [ ] All files properly organized

---

**Good luck with your assignment! This hands-on practice will solidify your Day 1 learning.**