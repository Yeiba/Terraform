variable "vpc_a_id" {
    description = "The ID of the VPC in which the NFS server resides"
    default     = "vpc-xxxxxxxxxxxx"  # Update with your VPC A ID
}

variable "vpc_a_cidr" {
    description = "CIDR block of VPC A"
    default     = "10.0.0.0/16"  # Update with your VPC A CIDR
}

variable "vpc_b_id" {
    description = "The ID of the VPC where the second Kubernetes cluster resides"
    default     = "vpc-yyyyyyyyyyyy"  # Update with your VPC B ID
}

variable "vpc_b_cidr" {
    description = "CIDR block of VPC B"
    default     = "10.1.0.0/16"  # Update with your VPC B CIDR
}
