variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "state_bucket_prefix" {
  description = "Prefix for the S3 state bucket name"
  type        = string
  default     = "terraform-state-demo"
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
  default     = "terraform-state-locks"
}