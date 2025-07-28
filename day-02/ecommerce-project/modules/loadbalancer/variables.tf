variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for load balancer"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for load balancer"
  type        = list(string)
}

variable "web_asg_name" {
  description = "Name of the web Auto Scaling Group"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}