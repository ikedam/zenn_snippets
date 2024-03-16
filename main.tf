terraform {
  required_version = "~> 1.7.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.20.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.41.0"
    }
  }
}

provider "google" {
}

# GCPのSecret ManagerからAWSの認証情報を取得する。
# ここでは アクセスキーID:シークレットアクセスキー のフォーマットで入れている。
data "google_secret_manager_secret_version" "aws_key" {
  secret = "terraform-aws-key"
}

provider "aws" {
  # GCPのSecret Managerから取得した認証情報でアクセスする。
  access_key = split(":", data.google_secret_manager_secret_version.aws_key.secret_data)[0]
  secret_key = split(":", data.google_secret_manager_secret_version.aws_key.secret_data)[1]
}

data "google_project" "project" {
}

output "project_number" {
  value = data.google_project.project.number
}

data "aws_caller_identity" "current" {
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
