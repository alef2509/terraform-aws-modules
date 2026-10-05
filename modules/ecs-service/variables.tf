variable "name" {
  description = "Name of the service (also the container name)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,32}$", var.name))
    error_message = "name must be 3-32 lowercase letters, digits or hyphens."
  }
}

variable "cluster_arn" {
  description = "ECS cluster that runs the service."
  type        = string
}

variable "vpc_id" {
  description = "VPC of the tasks."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets for the tasks."
  type        = list(string)
}

variable "image" {
  description = "Container image, ideally pinned by digest (repo@sha256:...)."
  type        = string
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "Task CPU units (256 = 0.25 vCPU)."
  type        = number
  default     = 512

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.cpu)
    error_message = "cpu must be a valid Fargate size: 256, 512, 1024, 2048 or 4096."
  }
}

variable "memory" {
  description = "Task memory in MiB (must be compatible with cpu)."
  type        = number
  default     = 1024
}

variable "cpu_architecture" {
  description = "ARM64 (Graviton, ~20% cheaper) or X86_64."
  type        = string
  default     = "ARM64"

  validation {
    condition     = contains(["ARM64", "X86_64"], var.cpu_architecture)
    error_message = "cpu_architecture must be ARM64 or X86_64."
  }
}

variable "desired_count" {
  description = "Initial number of tasks (autoscaling adjusts it afterwards)."
  type        = number
  default     = 2
}

variable "environment" {
  description = "Plain environment variables."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Environment variables read at start from Secrets Manager or SSM Parameter Store: NAME => ARN (a Secrets Manager ARN may end with :json-key::)."
  type        = map(string)
  default     = {}
}

variable "health_check_path" {
  description = "HTTP path used by the load balancer health check."
  type        = string
  default     = "/actuator/health/readiness"
}

variable "load_balancer" {
  description = "Attach to an ALB listener with path-based routing. Null for workers without HTTP traffic."
  type = object({
    listener_arn      = string
    security_group_id = string
    path_patterns     = list(string)
    priority          = number
  })
  default = null
}

variable "autoscaling" {
  description = "Target tracking on average CPU."
  type = object({
    min_capacity       = number
    max_capacity       = number
    target_cpu_percent = number
  })
  default = {
    min_capacity       = 2
    max_capacity       = 6
    target_cpu_percent = 60
  }

  validation {
    condition     = var.autoscaling.min_capacity <= var.autoscaling.max_capacity
    error_message = "autoscaling.min_capacity must not exceed max_capacity."
  }
}

variable "task_role_policy_json" {
  description = "IAM policy for the application itself (e.g. Kafka or S3 access). Null for no extra permissions."
  type        = string
  default     = null
}

variable "additional_security_group_ids" {
  description = "Extra security groups for the tasks."
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Retention of the container logs."
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
