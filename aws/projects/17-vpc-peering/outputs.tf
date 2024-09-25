output "vpc_peering_connection_id" {
  description = "VPC Peering Connection ID"
  value       = aws_vpc_peering_connection.vpc_peering.id
}

output "vpc_peering_status" {
  description = "VPC Peering Connection Status"
  value       = aws_vpc_peering_connection.vpc_peering.status
}
