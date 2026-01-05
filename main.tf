terraform {
  required_version = ">= 1.11.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.14.1"
    }
  }
}

provider "google" {
  project = var.google_project
}
