output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.main.id
}

output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "db_instance_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.main.name
}

output "db_secret_arn" {
  description = "ARN of the database secret"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "read_replica_endpoint" {
  description = "Read replica endpoint"
  value       = var.enable_read_replica ? aws_db_instance.read_replica[0].endpoint : null
  sensitive   = true
}