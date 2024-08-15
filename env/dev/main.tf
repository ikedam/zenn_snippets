terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.56.0"
    }
  }

  backend "s3" {
    # FIXME: バックエンド用に作成したS3バケットとDynamoDBテーブルを指定してください。
    # bucket         = "ACCOUNTID-tfstate-dev"
    key            = "rootmodule.tfstate"
    # dynamodb_table = "tfstate-lock"
  }
}

provider "aws" {
  # FIXME: ここで「使用されるはずのアカウントID」を指定する。
  # allowed_account_ids = [ACCOUNTID]
}

module "main" {
  source = "../.."

  basename = "terraform-rootmodule"
  env      = "dev"
}

output "main" {
  value = module.main
}
