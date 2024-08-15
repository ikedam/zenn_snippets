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
    # bucket = "ACCOUNTID-tfstate-dev"
    key    = "workspace.tfstate"
    # dynamodb_table = "tfstate-lock"
  }
}

check "workspace" {
  assert {
    condition     = terraform.workspace != "default"
    error_message = "You must set TF_WORKSPACE"
  }

  assert {
    condition     = contains(["dev", "stg", "prd"], terraform.workspace)
    error_message = "TF_WORKSPACE must be one of `dev`, `stg`, `prd`."
  }
}


# 以下のようにワークスペース名を「環境.アカウントID」のフォーマットで運用する方法も可能:
# locals {
#   env        = split(".", terraform.workspace)[0]
#   account_id = split(".", terraform.workspace)[1]
# }

# FIXME: 環境で使用するアカウントIDの対応表を作成します:
locals {
  env_configs = {
    # dev = {
    #   account_id = ACCOUNTID
    # }
    # stg = {
    #   account_id = ACCOUNTID
    # }
    # prd = {
    #   account_id = ACCOUNTID
    # }
  }

}

locals {
  env        = terraform.workspace
  account_id = local.env_configs[local.env].account_id
}


provider "aws" {
  allowed_account_ids = [local.account_id]
}

resource "aws_dynamodb_table" "table" {
  name         = "${var.basename}-${local.env}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Id"

  attribute {
    name = "Id"
    type = "S"
  }
}
