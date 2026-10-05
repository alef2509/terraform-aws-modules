variable "name" {
  description = "Name of the cluster."
  type        = string
}

variable "container_insights" {
  description = "CloudWatch Container Insights: \"disabled\", \"enabled\" or \"enhanced\"."
  type        = string
  default     = "enabled"

  validation {
    condition     = contains(["disabled", "enabled", "enhanced"], var.container_insights)
    error_message = "container_insights must be disabled, enabled or enhanced."
  }
}

variable "fargate_spot_weight" {
  description = "Share of tasks placed on FARGATE_SPOT (up to 70% cheaper, can be interrupted). 0 disables Spot; 1 base task always stays on regular Fargate."
  type        = number
  default     = 0

  validation {
    condition     = var.fargate_spot_weight >= 0 && var.fargate_spot_weight <= 100
    error_message = "fargate_spot_weight must be between 0 and 100."
  }
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
