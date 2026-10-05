variable "name" {
  description = "Name of the load balancer (max 32 characters)."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,32}$", var.name))
    error_message = "name must be at most 32 alphanumeric characters or hyphens."
  }
}

variable "vpc_id" {
  description = "VPC where the load balancer lives."
  type        = string
}

variable "subnet_ids" {
  description = "Public subnets (at least two AZs)."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "an Application Load Balancer needs subnets in at least two AZs."
  }
}

variable "certificate_arn" {
  description = "ACM certificate. When set, HTTPS is served on 443 and HTTP redirects to it; when null, only HTTP on 80 (demo environments)."
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "TLS policy of the HTTPS listener."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "ingress_cidr_blocks" {
  description = "Client CIDRs allowed to reach the load balancer."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "deletion_protection" {
  description = "Prevent accidental deletion (enable in production)."
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "Idle connection timeout, in seconds."
  type        = number
  default     = 60
}

variable "access_logs_bucket" {
  description = "S3 bucket for access logs (optional; the bucket policy must allow the ELB service)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
