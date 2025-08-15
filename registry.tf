resource "google_artifact_registry_repository" "app" {
  repository_id = replace(var.basename, "_", "-")
  format        = "DOCKER"

  cleanup_policies {
    id     = "delete-untagged-images-after-3-days"
    action = "DELETE"
    condition {
      tag_state  = "UNTAGGED"
      older_than = "3d"
    }
  }

  depends_on = [
    google_project_service.artifactregistry,
  ]
}

locals {
  registry_host = "${google_artifact_registry_repository.app.location}-docker.pkg.dev"
  registry_uri  = "${local.registry_host}/${local.project}/${google_artifact_registry_repository.app.name}"
}

resource "google_service_account" "imagepush" {
  account_id = "${var.basename}-imagepush"

  depends_on = [
    google_project_service.iam,
  ]
}

resource "google_service_account_key" "imagepush" {
  service_account_id = google_service_account.imagepush.name
}

resource "google_artifact_registry_repository_iam_member" "imagepush" {
  repository = google_artifact_registry_repository.app.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.imagepush.email}"
}

# https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs#registry-credentials
provider "docker" {
  # https://cloud.google.com/artifact-registry/docs/docker/authentication?hl=ja#json-key
  registry_auth {
    address  = "https://${google_artifact_registry_repository.app.location}-docker.pkg.dev"
    username = "_json_key_base64"
    password = google_service_account_key.imagepush.private_key
  }
}
