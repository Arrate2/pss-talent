terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Define la región de AWS a usar.
provider "aws" {
  region = var.aws_region
}
