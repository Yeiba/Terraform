terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49"
    }
  }
  backend "s3" {}
}
provider "aws" {
  profile = var.aws_profile
  region = var.aws_region
}