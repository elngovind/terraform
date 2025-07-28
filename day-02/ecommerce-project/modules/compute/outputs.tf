output "web_asg_name" {
  description = "Name of the web Auto Scaling Group"
  value       = aws_autoscaling_group.web.name
}

output "app_asg_name" {
  description = "Name of the app Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "web_launch_template_id" {
  description = "ID of the web launch template"
  value       = aws_launch_template.web.id
}

output "app_launch_template_id" {
  description = "ID of the app launch template"
  value       = aws_launch_template.app.id
}