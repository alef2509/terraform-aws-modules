output "arn" {
  description = "ARN of the cluster."
  value       = aws_msk_serverless_cluster.this.arn
}

output "bootstrap_brokers_sasl_iam" {
  description = "Bootstrap servers for SASL/IAM clients."
  value       = aws_msk_serverless_cluster.this.bootstrap_brokers_sasl_iam
}

output "security_group_id" {
  description = "Security group of the cluster."
  value       = aws_security_group.this.id
}

output "client_policy_json" {
  description = "IAM policy to attach to the task roles of producers and consumers."
  value       = data.aws_iam_policy_document.client.json
}
