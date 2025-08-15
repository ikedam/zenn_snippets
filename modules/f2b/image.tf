locals {
  source_path = "${path.module}/function"
}

module "changedetect" {
  source = "../docker_changedetect"

  source_path = local.source_path
  output_path = "${path.module}/function.zip"

  providers = {
    archive = archive
  }
}

resource "docker_image" "f2b" {
  name         = "${var.image_repository_uri}:latest"
  platform     = "linix/amd64"
  keep_locally = true
  build {
    context = local.source_path
  }
  triggers = {
    hash = module.changedetect.source_hash
  }
}

resource "docker_registry_image" "f2b" {
  name          = docker_image.f2b.name
  keep_remotely = true

  triggers = {
    hash = module.changedetect.source_hash
  }
}

locals {
  repo_image_uri = "${var.image_repository_uri}@${docker_registry_image.f2b.sha256_digest}"
}
