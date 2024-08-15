variable "basename" {
  type        = string
  description = "構築するリソースの共通prefix"
}

variable "env" {
  type        = string
  description = "構築する環境名"
}

variable "gcp_project" {
  type        = string
  description = "使用するGCPプロジェクトID"
}
