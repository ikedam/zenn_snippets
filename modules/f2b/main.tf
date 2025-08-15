# tflint-ignore: terraform_required_version
terraform {
  required_providers {
    # tflint-ignore: terraform_required_providers
    google = {
      source = "hashicorp/google"
    }
    # tflint-ignore: terraform_required_providers
    archive = {
      source = "hashicorp/archive"
    }
    # tflint-ignore: terraform_required_providers
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

data "google_project" "project" {
}

locals {
  project        = data.google_project.project.name
  project_number = data.google_project.project.number
}
