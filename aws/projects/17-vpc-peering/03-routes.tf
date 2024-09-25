# Route table for VPC A
resource "aws_vpc_route_table" "vpc_a_route_table" {
  vpc_id = var.vpc_a_id
}

# Update route tables for VPC A to route traffic to VPC B
resource "aws_route" "route_from_a_to_b" {
  route_table_id         = aws_vpc_route_table.vpc_a_route_table.id
  destination_cidr_block = var.vpc_b_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

# Route table for VPC B
resource "aws_vpc_route_table" "vpc_b_route_table" {
  vpc_id = var.vpc_b_id
}

# Update route tables for VPC B to route traffic to VPC A
resource "aws_route" "route_from_b_to_a" {
  route_table_id         = aws_vpc_route_table.vpc_b_route_table.id
  destination_cidr_block = var.vpc_a_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}
