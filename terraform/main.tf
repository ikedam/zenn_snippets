terraform {
  required_version = ">= 1.10.0"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7.0"
    }
  }
}

locals {
  source_root = "${path.module}/.."

  dockerignore_raw_lines     = split("\n", file("${local.source_root}/.dockerignore"))
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
  output_path      = "${path.module}/../source.zip"
  source_dir       = local.source_root
  excludes         = local.dockerignore_excludes
  output_file_mode = "0644"
}

output "source_hash" {
  value = data.archive_file.source.output_base64sha256
}

# dockerignore_excludes の中身を確認したい場合は
# ここをアンコメントして plan を実行すること。
# output "check_excludes" {
#   value = local.dockerignore_excludes
# }
