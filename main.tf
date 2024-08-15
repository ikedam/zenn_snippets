terraform {
  required_version = ">= 1.9.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.41.0"
    }
  }
}

resource "google_project_service" "artifactregistry" {
  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "repository" {
  repository_id = "${replace(var.basename, "_", "-")}-${var.env}"
  format        = "DOCKER"

  depends_on = [
    google_project_service.artifactregistry,
  ]
}
