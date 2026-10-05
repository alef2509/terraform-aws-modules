output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "availability_zones" {
  description = "Availability zones in use."
  value       = local.azs
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (load balancers, NAT gateways)."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (tasks, databases, Kafka)."
  value       = aws_subnet.private[*].id
}

output "nat_public_ips" {
  description = "Public IPs of the NAT gateways (allow-list these at third parties)."
  value       = aws_eip.nat[*].public_ip
}
