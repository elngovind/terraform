variable "ami_id" {
  description = "AMI ID for instances"
  type        = string
}

variable "web_instance_type" {
  description = "Instance type for web servers"
  type        = string
}

variable "app_instance_type" {
  description = "Instance type for app servers"
  type        = string
}

variable "web_subnet_ids" {
  description = "Subnet IDs for web servers"
  type        = list(string)
}

variable "app_subnet_ids" {
  description = "Subnet IDs for app servers"
  type        = list(string)
}

variable "web_security_group_ids" {
  description = "Security group IDs for web servers"
  type        = list(string)
}

variable "app_security_group_ids" {
  description = "Security group IDs for app servers"
  type        = list(string)
}

variable "web_min_size" {
  description = "Minimum size for web ASG"
  type        = number
}

variable "web_max_size" {
  description = "Maximum size for web ASG"
  type        = number
}

variable "app_min_size" {
  description = "Minimum size for app ASG"
  type        = number
}

variable "app_max_size" {
  description = "Maximum size for app ASG"
  type        = number
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

variable "db_endpoint" {
  description = "Database endpoint"
  type        = string
  sensitive   = true
}