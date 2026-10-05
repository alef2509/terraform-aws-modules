variable "region" {
  description = "AWS region."
  type        = string
  default     = "eu-west-1"
}

variable "image" {
  description = "Container image of the service."
  type        = string
  default     = "ghcr.io/alef2509/order-service:1.0.0"
}
