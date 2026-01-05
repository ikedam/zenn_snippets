variable "google_project" {
  type        = string
  description = "Google Cloud プロジェクト名"
}

# tflint-ignore: terraform_unused_declarations
variable "basename" {
  type        = string
  description = "構築するリソースの共通prefix"
  default     = "ephemeraltest"
}

# tflint-ignore: terraform_unused_declarations
variable "source_secret_id" {
  type        = string
  description = "手動作成したコピー元のシークレットID"
  default     = "ephemeraltest-copy-source"
}
