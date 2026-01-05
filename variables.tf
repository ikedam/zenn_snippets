variable "google_project" {
  type        = string
  description = "Google Cloud プロジェクト名"
}

variable "basename" {
  type        = string
  description = "構築するリソースの共通prefix"
  default     = "ephemeraltest"
}
