variable "basename" {
  type        = string
  description = "構築するリソースの共通prefix"
}

variable "env" {
  type        = string
  description = "構築する環境名"
}

variable "account_id" {
  type        = number
  description = "使用するAWSアカウントID"
}
