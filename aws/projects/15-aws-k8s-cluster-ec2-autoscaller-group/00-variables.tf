
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
variable "ami_id" {}
variable "master_instance_type" {}
variable "master_count" {}
variable "worker_instance_type" {}
variable "key_name" {}
variable "min_size" {}
variable "max_size" {}
variable "desired_capacity" {}


# S3
variable "s3_bucket_names" {}
variable "s3_bucket_name" {}
variable "s3_versioning" {}
variable "enable_lifecycle_rule" {}
variable "acl" {}


