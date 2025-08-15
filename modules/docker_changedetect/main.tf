# tflint-ignore: terraform_required_version
terraform {
  required_providers {
    # tflint-ignore: terraform_required_providers
    archive = {
      source = "hashicorp/archive"
    }
  }
}

locals {
  dockerignore_raw_lines     = split("\n", file("${var.source_path}/.dockerignore"))
  dockerignore_chomped_lines = [for line in local.dockerignore_raw_lines : chomp(line)]
  # 以下を除外する:
  # * コメント行
  # * 空行
  # * Dockerfile (Dockerfile もハッシュ計算の対象とする)
  dockerignore_skipped_lines = [
    for line in local.dockerignore_chomped_lines :
    line
    if !startswith(line, "#") && !contains(["", "Dockerfile", "/Dockerfile"], line)
  ]
  # 各 ignore 指定について以下のように扱う:
  # * / から始まるファイル → / を除外する
  # * / から始まらないファイル → 任意のサブディレクトリーに対する指定として、 **/ を追加する
  dockerignore_excludes = [
    for line in local.dockerignore_skipped_lines :
    (
      startswith(line, "/")
      ? trimprefix(line, "/")
      : "**/${line}"
    )
  ]
}

data "archive_file" "source" {
  type             = "zip"
  output_path      = var.output_path
  source_dir       = var.source_path
  excludes         = local.dockerignore_excludes
  output_file_mode = "0644"
}
