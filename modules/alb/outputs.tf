output "arn" {
  description = "ARN of the load balancer."
  value       = aws_lb.this.arn
}

output "dns_name" {
  description = "Public DNS name of the load balancer."
  value       = aws_lb.this.dns_name
}

output "zone_id" {
  description = "Route 53 zone of the load balancer, for alias records."
  value       = aws_lb.this.zone_id
}

output "listener_arn" {
  description = "Listener where services attach their routing rules (HTTPS when a certificate is set, else HTTP)."
  value       = local.https ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
}

output "security_group_id" {
  description = "Security group of the load balancer; allow it on the targets."
  value       = aws_security_group.this.id
}
