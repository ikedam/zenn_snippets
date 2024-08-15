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
    # bucket = "PROJECT-tfstate-stg"
    prefix = "rootmodule"
  }
}

provider "google" {
  # FIXME: ここに使用するGoogleプロジェクトを指定する。
  # project = "PROJECT"
  region  = "asia-northeast1"
}

module "main" {
  source = "../.."

  basename = "terraform-rootmodule"
  env      = "stg"
}

output "main" {
  value = module.main
}
