terraform {
  required_version = ">= 1.9.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.41.0"
    }
  }

  backend "gcs" {
    # FIXME: バックエンド用に作成したGCSバケットを指定してください。
    # bucket = "PROJECT-tfstate-dev"
    prefix = "workspace"
  }
}

resource "terraform_data" "workspace" {
  lifecycle {
    precondition {
      condition     = terraform.workspace != "default"
      error_message = "You must set TF_WORKSPACE"
    }

    precondition {
      condition     = (terraform.workspace == "default") || contains(["dev", "stg", "prd"], terraform.workspace)
      error_message = "TF_WORKSPACE must be one of `dev`, `stg`, `prd`."
    }
  }
}

# FIXME: 環境で使用するプロジェクトIDの対応表を作成します:
locals {
  env_configs = {
    # dev = {
    #   gcp_project = "PROJECT"
    # }
    # stg = {
    #   gcp_project = "PROJECT"
    # }
    # prd = {
    #   gcp_project = "PROJECT"
    # }
  }
}

locals {
  env         = terraform.workspace
  gcp_project = lookup(local.env_configs, local.env, local.env_configs["dev"]).gcp_project
}

provider "google" {
  project = local.gcp_project
  region  = "asia-northeast1"
}

resource "google_project_service" "artifactregistry" {
  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "repository" {
  repository_id = "${replace(var.basename, "_", "-")}-${local.env}"
  format        = "DOCKER"

  depends_on = [
    google_project_service.artifactregistry,
  ]
}
