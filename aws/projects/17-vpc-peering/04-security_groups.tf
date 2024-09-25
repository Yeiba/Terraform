# Security Group for VPC A (NFS Server)
resource "aws_security_group_rule" "allow_traffic_from_vpc_b" {
  type        = "ingress"
  from_port   = 2049  # NFS port
  to_port     = 2049
  protocol    = "tcp"
  cidr_blocks = [var.vpc_b_cidr]

  security_group_id = aws_security_group.vpc_a_nfs_sg.id
}

# Security Group for VPC B (Cluster)
resource "aws_security_group_rule" "allow_traffic_from_vpc_a" {
  type        = "ingress"
  from_port   = 2049
  to_port     = 2049
  protocol    = "tcp"
  cidr_blocks = [var.vpc_a_cidr]

  security_group_id = aws_security_group.vpc_b_cluster_sg.id
}
