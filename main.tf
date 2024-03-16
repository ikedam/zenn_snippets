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

provider "aws" {
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
