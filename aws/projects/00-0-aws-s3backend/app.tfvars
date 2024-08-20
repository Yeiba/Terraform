
# Common
project       = "JACOB"
prefix        = "tf-backend"
org_unit      = "JACOB"
business_unit = "SMB-INT" # SMB-INT - Small & Medium Business in Org, "SMB-EXTR" - SMB External
cost_center   = "CCAWS0000"
appid         = "APP001"

# General 
aws_region  = "us-east-1"
aws_profile = "default"
suffix      = "01"

# S3
s3_bucket_names       = []
s3_bucket_name        = "jacob-tf-states"
s3_versioning         = "Enabled"
enable_lifecycle_rule = false

db_table_name = "jacob-tf-locks"
billing_mode  = "PAY_PER_REQUEST"
hash_key      = "LockID"
attr_name     = "LockID"
attr_type     = "S"