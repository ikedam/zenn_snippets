# CloudRunのデプロイを行うTerraformテンプレート

terraform {
  required_version = "~> 1.7.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.39.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.4.2"
    }
    containerregistry = {
      source  = "tf-containerregistry.ikedam.jp/ikedam/containerregistry"
      version = "0.2.5"
    }
  }
}

provider "google" {
  region = "asia-northeast1"
}

data "google_project" "project" {
}

resource "google_project_service" "iam" {
  service = "iam.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "run" {
  service = "run.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "image_registry" {
  repository_id = replace(var.basename, "_", "-")
  format        = "DOCKER"

  docker_config {
    immutable_tags = true
  }

  depends_on = [
    google_project_service.artifactregistry,
  ]
}

locals {
  registry_host = "${google_artifact_registry_repository.image_registry.location}-docker.pkg.dev"
  registry_uri  = "${local.registry_host}/${data.google_project.project.project_id}/${google_artifact_registry_repository.image_registry.name}"
}


# イメージのリビルド判定用
data "archive_file" "webapp" {
  type        = "zip"
  output_path = "${path.module}/webapp.zip"
  source_dir  = "${path.module}/webapp"
  # .dockerignore 相当の指定を行う。
  excludes = setunion(
    fileset("${path.module}/webapp", ".dockerignore"),
  )
}

resource "containerregistry_image" "webapp" {
  image_uri = "${local.registry_uri}/webapp:latest"

  # build には、 docker compose v2 互換のビルド指定を記述します。
  # See: https://docs.docker.com/reference/compose-file/build/
  # ただし、 label の指定だけは build と同レベルに存在する labels で指定を行ってください。
  build = jsonencode({
    context   = "${path.module}/webapp"
    platforms = ["linux/amd64"]
  })

  labels = {
    sha256 = data.archive_file.webapp.output_sha256
  }

  triggers = {
    sha256 = data.archive_file.webapp.output_sha256
  }

  auth = {
    google_artifact_registry = {}
  }
}

locals {
  repo_image_uri = "${local.registry_uri}/webapp@${containerregistry_image.webapp.sha256_digest}"
}

resource "google_cloud_run_v2_service" "webapp" {
  name     = "${var.basename}-service"
  location = "asia-northeast1"

  template {
    containers {
      image = local.repo_image_uri
    }
  }

  depends_on = [
    google_project_service.run,
  ]
}

# 公開アクセスの許可
resource "google_cloud_run_service_iam_binding" "webapp_public" {
  location = google_cloud_run_v2_service.webapp.location
  service  = google_cloud_run_v2_service.webapp.name
  role     = "roles/run.invoker"
  members = [
    "allUsers"
  ]
}
