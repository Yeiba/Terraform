# Step 1: Create VPC Peering Connection
resource "aws_vpc_peering_connection" "vpc_peering" {
  peer_vpc_id = var.vpc_b_id
  vpc_id      = var.vpc_a_id

  auto_accept = false  # Disable auto accept, we’ll accept manually later
}

# Step 2: Accept VPC Peering Connection in VPC B
resource "aws_vpc_peering_connection_accepter" "accept_peering" {
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
  auto_accept               = true

  accepter {
    vpc_id = var.vpc_b_id
  }

  requester {
    vpc_id = var.vpc_a_id
  }
}

# Enable DNS resolution between VPCs
resource "aws_vpc_peering_connection_options" "requester_options" {
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id

  requester {
    allow_dns_resolution_from_remote_vpc = true
  }
}

resource "aws_vpc_peering_connection_options" "accepter_options" {
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id

  accepter {
    allow_dns_resolution_from_remote_vpc = true
  }
}
