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
    # https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
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
  repository = google_artifact_registry_repository.image_registry.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.imagepush.email}"
}

# https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs#registry-credentials
provider "docker" {
  # https://cloud.google.com/artifact-registry/docs/docker/authentication?hl=ja#json-key
  registry_auth {
    address  = "https://${google_artifact_registry_repository.image_registry.location}-docker.pkg.dev"
    username = "_json_key_base64"
    password = google_service_account_key.imagepush.private_key
  }
}

# サービスアカウントの代わりに以下でもいける。
# ただし Terraform のステートファイルに実行者のトークン(60分有効)が保存されてしまうため危険。
# プッシュ専用のサービスアカウントを作るほうがセキュリティリスクの影響範囲を抑えられる。
# data "google_client_config" "current" {
# }

# provider "docker" {
#   # https://cloud.google.com/artifact-registry/docs/docker/authentication?hl=ja#token
#   registry_auth {
#     address  = "https://${google_artifact_registry_repository.image_registry.location}-docker.pkg.dev"
#     username = "oauth2accesstoken"
#     password = data.google_client_config.current.access_token
#   }
# }

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

resource "docker_image" "webapp" {
  name         = "${local.registry_uri}/webapp:latest"
  platform     = "linix/amd64"
  keep_locally = true
  build {
    context = "${path.module}/webapp"
  }
  triggers = {
    sha256 = data.archive_file.webapp.output_sha256
  }
}

resource "docker_registry_image" "webapp" {
  name          = docker_image.webapp.name
  keep_remotely = true

  triggers = {
    sha256 = data.archive_file.webapp.output_sha256
  }
}

locals {
  repo_image_uri = "${local.registry_uri}/webapp@${docker_registry_image.webapp.sha256_digest}"
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
