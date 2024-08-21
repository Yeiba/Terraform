
# Tags
variable "project" {}
variable "prefix" {}
variable "suffix" {}
variable "createdby" {}
variable "org_unit" {}
variable "business_unit" {}
variable "cost_center" {}
variable "appid" {}
variable "env" {}

# General 
variable "region" {}
variable "zone1" {}
variable "zone2" {}
variable "eks_name" {}
variable "eks_version" {}

# vpc
variable "vpc_ip_range" {}

# subnet
variable "subnet_private_ip_range_zone1" {}
variable "subnet_private_ip_range_zone2" {}
variable "subnet_public_ip_range_zone1" {}
variable "subnet_public_ip_range_zone2" {}

# net
variable "net_domain" {}

# nodes
variable "node_group_name" {}
variable "capacity_type" {}
variable "instance_types" {}
variable "desired_size" {}
variable "max_size" {}
variable "min_size" {}
variable "max_unavailable" {}
variable "role" {}

# S3
variable "s3_bucket_names" {}
variable "s3_bucket_name" {}
variable "s3_versioning" {}
variable "enable_lifecycle_rule" {}
variable "acl" {}


