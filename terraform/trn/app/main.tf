terraform {
  required_version = "1.0.0" # must match value in .github/workflows/*.yml
  backend "s3" {
    # The name of your terraform state storage bucket. Name it whatever you want.
    bucket = "terraform-state-storage-226865294839"
    # The name of your terraform state lock dynamo table. Name it whatever you want. 
    dynamodb_table = "terraform-state-lock-226865294839"
    key            = "magic-8-ball/app.tfstate"
    region         = "us-west-2"
  }
}

#We are building this project in Oregon
provider "aws" {
  region = "us-west-2"
  alias  = "us-west-2"
}

# ACM Certificates must be created in Virgina. For this reason we have to
# delcare a second provider.
provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
}

module "app" {
  source   = "../../modules/app/"
  env      = "trn"
  app_name = "magic_8_ball"
  # Change this to be your AWS account number
  account_number = "226865294839"
  # Change this to be your domain name
  domain_name = "8-ball.ml"
  # Change this to be your hosted zone id
  hosted_zone_id = "Z09767571D0IVLLXRR8P3"
  tags = {
    repo = "https://github.com/jjricks6/magic-8-ball"
    app  = "magic_8_ball"
    env  = "trn"
  }
  providers = {
    aws.us-west-2 = aws.us-west-2
    aws.us-east-1 = aws.us-east-1
  }

}