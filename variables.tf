variable "project" {
  description = "project"
  type        = string
}

variable "region" {
  description = "region"
  type        = string
}

variable "basename" {
  description = "basename for resources"
  type        = string
  default     = "f2bdemo"
}

variable "max_staleness" {
  description = "max staleness for BigQuery table. Write in `INTERVAL 30 MINUTE` format."
  type        = string
  nullable    = true
  default     = null
}