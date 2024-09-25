Here’s how you can create a VPC Peering connection between two VPCs in AWS using Terraform.

### Assumptions:

1. **VPC A**: This is the VPC where the NFS server resides.
2. **VPC B**: This is the VPC where the second Kubernetes cluster resides.

### Steps:

1. Create a VPC Peering connection between the two VPCs.
2. Modify the route tables in both VPCs to allow traffic to flow between them via the peering connection.
3. Configure security groups to allow traffic between the VPCs.
4. Enable DNS resolution between the VPCs.

### Terraform Example:

This configuration assumes that you have already created two VPCs (`vpc_a` and `vpc_b`).

#### 1. Create a VPC Peering Connection

```hcl
provider "aws" {
  region = "us-east-1"  # Set your region here
}

# VPC A Variables
variable "vpc_a_id" {
  description = "The ID of the VPC in which NFS server resides"
  default     = "vpc-xxxxxxxxxxxx"  # Update with your VPC A ID
}

variable "vpc_a_cidr" {
  description = "CIDR block of VPC A"
  default     = "10.0.0.0/16"  # Update with your VPC A CIDR
}

# VPC B Variables
variable "vpc_b_id" {
  description = "The ID of the VPC where the second Kubernetes cluster resides"
  default     = "vpc-yyyyyyyyyyyy"  # Update with your VPC B ID
}

variable "vpc_b_cidr" {
  description = "CIDR block of VPC B"
  default     = "10.1.0.0/16"  # Update with your VPC B CIDR
}

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

# Step 3: Update Route Tables for VPC A
resource "aws_route" "route_from_a_to_b" {
  route_table_id         = aws_vpc_route_table.vpc_a_route_table.id
  destination_cidr_block = var.vpc_b_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

# Step 4: Update Route Tables for VPC B
resource "aws_route" "route_from_b_to_a" {
  route_table_id         = aws_vpc_route_table.vpc_b_route_table.id
  destination_cidr_block = var.vpc_a_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

# Assuming route tables for VPC A and VPC B are already created.
resource "aws_vpc_route_table" "vpc_a_route_table" {
  vpc_id = var.vpc_a_id
}

resource "aws_vpc_route_table" "vpc_b_route_table" {
  vpc_id = var.vpc_b_id
}

```

#### 2. Modify Security Groups

Ensure that the security group attached to the NFS server allows inbound traffic from VPC B.

```hcl
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
```

#### 3. Enable DNS Resolution Between VPCs (Optional)

You might need to enable DNS resolution for peering connection if you rely on DNS for NFS access.

```hcl
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
```

### How to Apply the Configuration:

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```
2. **Plan**: Check what Terraform will create:
   ```bash
   terraform plan
   ```
3. **Apply**: Apply the changes:
   ```bash
   terraform apply
   ```

### Summary:

- The above Terraform configuration will:
  - Set up a VPC Peering connection between two VPCs.
  - Update route tables in both VPCs to allow traffic to flow via the peering connection.
  - Update security groups to allow NFS traffic between the two VPCs.
  - Optionally, enable DNS resolution for the peering connection.

After this, your second Kubernetes cluster should be able to access the NFS service hosted in the first Kubernetes cluster via the VPC Peering connection.


The provided Terraform configuration for creating a VPC peering connection is meant to be used **independently**. Here’s how you can think about its integration:

### 1. **Independent Module**

- The VPC peering configuration can be treated as a standalone Terraform module that can be applied independently of the NFS server or the first Kubernetes cluster. This allows you to manage the networking aspect between the two VPCs separately.
- You can apply this configuration to establish the peering connection first, then move on to set up the NFS server or any other resources that will utilize this peering connection.

### 2. **Integration with Other Terraform Configurations**

- After creating the VPC peering connection using the above configuration, you can reference it in your NFS server cluster Terraform configuration or the first Kubernetes cluster configuration. For instance:
  - **NFS Server Cluster Terraform**: You can add routes in the NFS server's security group to allow incoming traffic from the other VPC.
  - **First Kubernetes Cluster Terraform**: You can configure routes in the Kubernetes cluster to enable communication with the NFS server located in the other VPC.

### 3. **Considerations for Deployment**

- When you plan to deploy resources that rely on this peering connection (like your NFS server or Kubernetes clusters), make sure to:
  - First apply the VPC peering Terraform configuration.
  - Then configure and deploy your NFS server and other resources that will use this peering connection.

### Summary

- Use the provided Terraform configuration as a separate step in your infrastructure setup. Once the peering connection is established, ensure your NFS server and other resources are configured to utilize this connection effectively. This modular approach helps keep your infrastructure organized and manageable.
