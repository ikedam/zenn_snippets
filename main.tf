terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.56.0"
    }
  }

  backend "s3" {
    bucket         = "${var.account_id}-tfstate-${var.env}"
    key            = "opentofu-env-demo.tfstate"
    dynamodb_table = "tfstate-lock"
  }
}

provider "aws" {
  allowed_account_ids = [var.account_id]
}

resource "aws_dynamodb_table" "table" {
  name         = "${var.basename}-${var.env}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Id"

  attribute {
    name = "Id"
    type = "S"
  }
}
