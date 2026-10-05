output "url" {
  description = "Public URL of the load balancer."
  value       = "http://${module.alb.dns_name}"
}
