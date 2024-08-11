terraform {
  required_version = "~> 1.9.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.39.0"
    }
  }
}

provider "google" {
  region = "asia-northeast2"
  zone   = "asia-northeast2-a"
}

data "google_project" "project" {
}

data "google_client_config" "current" {
}
