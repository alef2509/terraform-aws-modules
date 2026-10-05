variable "role_name" {
  description = "Name of the IAM role assumed by GitHub Actions."
  type        = string
}

variable "subjects" {
  description = <<-EOT
    Allowed OIDC subjects, e.g. "repo:alef2509/aws-infra-live:ref:refs/heads/main"
    or "repo:alef2509/aws-infra-live:environment:prod". Wildcards (*) are allowed
    but should never cover a whole organization.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.subjects) > 0 && alltrue([for s in var.subjects : can(regex("^repo:[^/*]+/[^:*]+:", s))])
    error_message = "each subject must pin an owner and repository: repo:<owner>/<repo>:..."
  }
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider (only one per AWS account; set false if it already exists)."
  type        = bool
  default     = true
}

variable "managed_policy_arns" {
  description = "Managed policies attached to the role."
  type        = list(string)
  default     = []
}

variable "inline_policy_json" {
  description = "Inline policy for the role."
  type        = string
  default     = null
}

variable "max_session_duration" {
  description = "Maximum session length in seconds."
  type        = number
  default     = 3600
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
