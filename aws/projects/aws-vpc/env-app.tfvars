

# Common

project = "project-env"

# General 
aws_region       = "us-east-1"
profile          = "development"
tf_workspace_env = "dev"

# VPC 
create_vpc           = true
name                 = "jacob"
cidr                 = "10.0.0.0"
instance_tenancy     = "default"
enable_dns_hostnames = true
enable_dns_support   = true
create_igw           = true