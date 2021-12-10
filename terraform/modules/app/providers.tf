terraform {
  required_version = ">=1.0.0"
  required_providers {
    aws = {
      version               = "~>3.56.0"
      source                = "hashicorp/aws"
      configuration_aliases = [aws.us-west-2, aws.us-east-1]
    }
  }
}