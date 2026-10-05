output "arn" {
  description = "ARN of the cluster."
  value       = aws_ecs_cluster.this.arn
}

output "name" {
  description = "Name of the cluster."
  value       = aws_ecs_cluster.this.name
}
