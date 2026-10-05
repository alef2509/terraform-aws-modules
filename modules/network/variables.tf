variable "name" {
  description = "Name prefix for every resource."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,32}$", var.name))
    error_message = "name must be 3-32 lowercase letters, digits or hyphens."
  }
}

variable "cidr_block" {
  description = "IPv4 CIDR of the VPC. A /16 is split into /20 subnets."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.cidr_block)) && tonumber(split("/", var.cidr_block)[1]) <= 20
    error_message = "cidr_block must be a valid IPv4 CIDR of /20 or larger."
  }
}

variable "az_count" {
  description = "Number of availability zones (one public and one private subnet each)."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3."
  }
}

variable "nat_gateway_mode" {
  description = <<-EOT
    Outbound internet access for private subnets:
    "none" (cheapest; use VPC endpoints), "single" (one NAT, dev), "one_per_az" (highly available, prod).
  EOT
  type        = string
  default     = "single"

  validation {
    condition     = contains(["none", "single", "one_per_az"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be none, single or one_per_az."
  }
}

variable "enable_flow_logs" {
  description = "Send VPC flow logs (rejected traffic) to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Retention of the flow logs log group."
  type        = number
  default     = 30
}

variable "kms_key_arn" {
  description = "Customer managed KMS key for the log group (optional)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
