# Terraform Day 01 - Infrastructure as Code Fundamentals
## 150 Minutes Lecture Structure

---

## **Slide 1: Welcome & Agenda**
**Time: 0-5 minutes**

### Terraform Day 01 - Infrastructure as Code
- **Duration:** 150 minutes (2.5 hours)
- **Breaks:** 10 min at 60 min, 10 min at 120 min
- **Format:** Interactive lecture with hands-on examples

### Today's Journey
1. Manual Deployment Challenges (15 min)
2. Evolution of Infrastructure Management (20 min)
3. Types of IaC Tools (25 min)
4. Why Terraform? (20 min)
5. Terraform Core Concepts (25 min)
6. HCL Basics & First Resource (20 min)

---

## **Slide 2: Manual Deployment Challenges**
**Time: 5-20 minutes**

### The Old Way: Manual Infrastructure
- **Human Error** - Typos, missed steps, inconsistent configs
- **Time Consuming** - Hours/days for complex setups
- **No Version Control** - Can't track changes or rollback
- **Documentation Drift** - Docs become outdated
- **Scaling Issues** - Manual work doesn't scale
- **Environment Inconsistency** - Dev ##‰  Staging ##‰  Production

### Real-World Pain Points
- "It works on my machine"
- Server configuration snowflakes
- Disaster recovery nightmares
- Compliance and audit challenges

---

## **Slide 3: How Infrastructure Management Evolved**
**Time: 20-40 minutes**

### Evolution Timeline
```
Manual Scripts ##†## Configuration Management ##†## Infrastructure as Code
     ##†##                    ##†##                        ##†##
   Bash/PowerShell    Ansible/Puppet         Terraform/CloudFormation
```

### The IaC Revolution
- **Declarative** - Describe what you want, not how
- **Version Controlled** - Git for infrastructure
- **Repeatable** - Same result every time
- **Collaborative** - Team-based infrastructure
- **Auditable** - Track all changes

---

## **Slide 4: Types of IaC Tools Overview**
**Time: 40-65 minutes**

### Three Categories of IaC Tools

## 1. Configuration Management
- **Ansible** - Agentless, YAML-based
- **Puppet** - Agent-based, declarative
- **Chef** - Agent-based, Ruby DSL
- **SaltStack** - Agent/agentless, Python-based

## 2. Server Templating
- **Docker** - Container images
- **Packer** - VM/AMI images
- **Vagrant** - Development environments

## 3. Provisioning Tools
- **Terraform** - Multi-cloud provisioning
- **CloudFormation** - AWS-specific
- **Pulumi** - Programming language-based

---

## **Slide 5: Configuration Management Deep Dive**
**Time: 65-75 minutes**

### Configuration Management Tools
**Purpose:** Install and manage software on existing servers

### Key Characteristics
- **Standard Structure** - Consistent server configurations
- **Version Control** - Track configuration changes
- **Idempotent** - Safe to run multiple times
- **Agent-based/Agentless** - Different deployment models

### Example: Ansible Playbook
```yaml
- name: Install web server
  hosts: webservers
  tasks:
    - name: Install Apache
      yum: name=httpd state=present
    - name: Start Apache
      service: name=httpd state=started
```

---

## **Slide 6: Server Templating Tools**
**Time: 75-85 minutes**

### Server Templating Philosophy
**Purpose:** Pre-install software and dependencies into images

### Key Benefits
- **Immutable Infrastructure** - Replace, don't modify
- **Faster Deployments** - Pre-built images
- **Consistency** - Same image across environments
- **Rollback Capability** - Previous image versions

### Examples
- **Docker:** Container images with applications
- **Packer:** VM images (AMIs, VMDKs)
- **Vagrant:** Development environment boxes

### Immutable vs Mutable
```
Mutable: Server ##†## Configure ##†## Update ##†## Patch
Immutable: Image ##†## Deploy ##†## Replace ##†## Deploy New Image
```

---

## **Slide 7: Provisioning Tools**
**Time: 85-95 minutes**

### Provisioning Tools Purpose
**Deploy immutable infrastructure resources**

### What They Provision
- **Servers** - EC2, VMs, Containers
- **Databases** - RDS, DynamoDB, MongoDB
- **Network Components** - VPCs, Subnets, Load Balancers
- **Security** - IAM, Security Groups, Policies

### Multi-Provider Support
- **Cloud Providers** - AWS, Azure, GCP
- **On-Premises** - VMware, OpenStack
- **SaaS** - GitHub, DataDog, Auth0

---

## **BREAK: 10 Minutes (95-105)**

---

## **Slide 8: Why Terraform?**
**Time: 105-125 minutes**

### Terraform's Unique Advantages

## 1. Multi-Platform Support
- **Physical Machines** - Bare metal servers
- **Virtualization** - VMware vSphere
- **Cloud Providers** - AWS, Azure, GCP
- **Hybrid/Multi-Cloud** - Consistent tooling

## 2. Massive Provider Ecosystem
**Infrastructure Providers:**
- AWS, Azure, GCP, Alibaba Cloud
- VMware, OpenStack, Kubernetes

**Monitoring & Security:**
- DataDog, Grafana, Sumo Logic
- Palo Alto, Auth0, Vault

**Databases & Storage:**
- MongoDB, MySQL, PostgreSQL
- InfluxDB, Elasticsearch

---

## **Slide 9: Terraform Providers**
**Time: 125-130 minutes**

### Popular Terraform Providers
```
Infrastructure:     Monitoring:        Security:
##¢ AWS              ##¢ DataDog          ##¢ Auth0
##¢ Azure            ##¢ Grafana          ##¢ Palo Alto
##¢ GCP              ##¢ Wavefront        ##¢ Vault
##¢ VMware           ##¢ Sumo Logic       ##¢ Okta

Networking:        Databases:         Version Control:
##¢ CloudFlare       ##¢ MongoDB          ##¢ GitHub
##¢ BigIP            ##¢ MySQL            ##¢ GitLab
##¢ DNS              ##¢ PostgreSQL       ##¢ Bitbucket
##¢ Infoblox         ##¢ InfluxDB         ##¢ Azure DevOps
```

### Provider Registry
**registry.terraform.io** - Official provider documentation

---

## **Slide 10: Terraform Core Concepts**
**Time: 130-140 minutes**

### Declarative Approach
```hcl
# main.tf - What you want
resource "aws_instance" "webserver" {
  ami           = "ami-0edab43b6fa892279"
  instance_type = "t2.micro"
  
  tags = {
    Name = "WebServer"
  }
}

resource "aws_s3_bucket" "finance" {
  bucket = "finance-21092020"
  
  tags = {
    Description = "Finance and Payroll"
  }
}
```

### Terraform Workflow
```
Write ##†## Plan ##†## Apply
  ##†##      ##†##      ##†##
main.tf ##†## Preview ##†## Deploy
```

---

## **Slide 11: Terraform State Management**
**Time: 140-145 minutes**

### Terraform State (terraform.tfstate)
```
Real World Infrastructure ##†##†## terraform.tfstate ##†##†## Configuration Files
         ##†‘                                              ##†‘
    AWS Resources                                   main.tf
```

### State File Purpose
- **Resource Tracking** - Maps config to real resources
- **Metadata Storage** - Resource dependencies
- **Performance** - Caches resource attributes
- **Collaboration** - Shared state for teams

### Terraform Import
```bash
# Import existing resources
terraform import aws_instance.webserver i-1234567890abcdef0
```

---

## **Slide 12: HCL Basics - First Resource**
**Time: 145-150 minutes**

### HashiCorp Configuration Language (HCL)
**Declarative language designed for infrastructure**

### Basic Syntax Structure
```hcl
# local.tf
resource "local_file" "pet" {
  filename = "/root/pets.txt"
  content  = "We love pets!"
}
```

### HCL Components Breakdown
```
provider = local
resource_type = file
resource_name = pet

Arguments:
##œ###### filename = "/root/pets.txt"
########## content = "We love pets!"
```

### Resource Documentation
**registry.terraform.io/providers/hashicorp/local/latest/docs**

---

## **Slide 13: Terraform Installation & Next Steps**
**Time: 150 minutes - Wrap Up**

### Installation Options
- **Binary Download** - terraform.io/downloads
- **Package Managers** - brew, apt, yum
- **Docker** - hashicorp/terraform image

### What's Coming Next
- **Day 02:** Terraform Commands & Workflow
- **Day 03:** Variables, Outputs & Data Sources
- **Day 04:** Modules & Best Practices
- **Day 05:** State Management & Team Collaboration

### Homework
1. Install Terraform on your machine
2. Create your first local_file resource
3. Explore terraform.io/registry

---

## **Lecture Notes for Instructor**

### Timing Breakdown (150 minutes total)
- **Introduction & Manual Challenges:** 20 minutes
- **Evolution & Tool Types:** 45 minutes
- **Break:** 10 minutes
- **Why Terraform & Providers:** 20 minutes
- **Core Concepts:** 15 minutes
- **HCL Basics:** 15 minutes
- **Installation & Wrap-up:** 5 minutes
- **Q&A Buffer:** 20 minutes

### Interactive Elements
1. **Poll:** "Who has used manual deployment?" (Slide 2)
2. **Discussion:** "Share your infrastructure horror stories" (Slide 2)
3. **Hands-on:** Create first local_file resource (Slide 12)
4. **Q&A:** Throughout each section

### Key Takeaways
- Manual deployment doesn't scale
- IaC tools solve different problems
- Terraform excels at multi-cloud provisioning
- Declarative approach is powerful
- State management is crucial
- HCL is simple but powerful

### Materials Needed
- Laptop with Terraform installed
- Text editor (VS Code recommended)
- Terminal access
- Internet connection for registry.terraform.io