terraform {
  required_version = "1.0.0" # must match value in .github/workflows/*.yml
  backend "s3" {
    bucket         = "terraform-state-storage-226865294839"
    dynamodb_table = "terraform-state-lock-226865294839"
    key            = "magic-8-ball/app.tfstate"
    region         = "us-west-2"
  }
}

provider "aws" {
  region = "us-west-2"
}

module "app" {
  source         = "../../modules/app/"
  env            = "trn"
  app_name       = "magic_8_ball"
  account_number = "226865294839"
  domain_name    = "8-ball.ml"
  hosted_zone_id = "Z09767571D0IVLLXRR8P3"
  tags = {
    repo = "https://github.com/jjricks6/magic-8-ball"
    app  = "magic_8_ball"
    env  = "trn"
  }

}