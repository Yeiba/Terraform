locals {
  env         = "staging"
  region      = "us-east-2"
  zone1       = "us-east-2a"
  zone2       = "us-east-2b"
  eks_name    = "demo"
  eks_version = "1.29"
  profile     = "development"
  prod_account_id = "123456789012"
  crossAccountRole = "crossAccountRole-full_admin"
}