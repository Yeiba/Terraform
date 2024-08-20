provider "aws" {
  region = local.region
  profile= local.profile

}

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