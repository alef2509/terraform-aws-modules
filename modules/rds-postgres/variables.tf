variable "identifier" {
  description = "Identifier of the DB instance."
  type        = string
}

variable "vpc_id" {
  description = "VPC of the database."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets (at least two AZs)."
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect on 5432 (e.g. the ECS services)."
  type        = list(string)
  default     = []
}

variable "database_name" {
  description = "Name of the initial database."
  type        = string
}

variable "master_username" {
  description = "Master user. Its password is generated and rotated by Secrets Manager, never stored in Terraform state."
  type        = string
  default     = "app_admin"
}

variable "engine_version" {
  description = "Major PostgreSQL version."
  type        = string
  default     = "17"
}

variable "instance_class" {
  description = "Instance size. Graviton burstable classes are the cheapest for dev."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Initial storage in GiB (gp3)."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Storage autoscaling ceiling in GiB."
  type        = number
  default     = 100
}

variable "multi_az" {
  description = "Synchronous standby in another AZ (production)."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Automated backup retention."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "backup_retention_days must be between 1 and 35."
  }
}

variable "deletion_protection" {
  description = "Block deletion; when false a final snapshot is still taken."
  type        = bool
  default     = true
}

variable "enable_logical_replication" {
  description = "Set rds.logical_replication=1, required for change data capture (Debezium outbox relay)."
  type        = bool
  default     = false
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0 disables; 1, 5, 10, 15, 30 or 60)."
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "monitoring_interval must be 0, 1, 5, 10, 15, 30 or 60."
  }
}

variable "kms_key_arn" {
  description = "Customer managed KMS key for storage and Performance Insights (optional; AWS managed key otherwise)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
