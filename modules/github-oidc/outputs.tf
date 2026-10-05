output "role_arn" {
  description = "Role ARN to use in aws-actions/configure-aws-credentials (role-to-assume)."
  value       = aws_iam_role.this.arn
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider."
  value       = local.provider_arn
}
