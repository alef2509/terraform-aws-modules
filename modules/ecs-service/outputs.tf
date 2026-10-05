output "service_name" {
  description = "Name of the ECS service."
  value       = aws_ecs_service.this.name
}

output "security_group_id" {
  description = "Security group of the tasks; allow it on databases and brokers."
  value       = aws_security_group.this.id
}

output "task_role_arn" {
  description = "Role assumed by the application code."
  value       = aws_iam_role.task.arn
}

output "execution_role_arn" {
  description = "Role used by ECS to pull the image, write logs and read secrets."
  value       = aws_iam_role.execution.arn
}

output "target_group_arn" {
  description = "Target group, when attached to a load balancer."
  value       = var.load_balancer != null ? aws_lb_target_group.this[0].arn : null
}

output "log_group_name" {
  description = "CloudWatch log group of the containers."
  value       = aws_cloudwatch_log_group.this.name
}
