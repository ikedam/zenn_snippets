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

provider "aws" {
}

# AWS Secrets ManagerからGCPの認証情報(サービスアカウントのJSONキー)を取得する。
data "aws_secretsmanager_secret_version" "gcp_key" {
  secret_id = "terraform-gcp-key"
}

provider "google" {
  # AWS Secrets Managerから取得した認証情報で認証する。
  credentials = data.aws_secretsmanager_secret_version.gcp_key.secret_string
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
