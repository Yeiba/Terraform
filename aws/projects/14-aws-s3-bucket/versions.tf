terraform {
  required_version = "~> 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.37.0"
    }
  }
  # backend "s3" {}
}
provider "aws" {
  profile = var.aws_profile
  region = var.aws_region
}