terraform {
  required_version = "~> 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.37.0"
    }
  }

  # TF State Management
  # Variables not allowed in backend block. 
  backend "s3" {}
}

# provider block

provider "aws" {
  profile = var.aws_profile
  #shared_credentials_file ="/path/to/.aws/credentials"
  region = var.aws_region
  #alias   = "us-east-1"
}