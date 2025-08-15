variable "basename" {
  description = "basename of resources"
  type        = string
}

variable "collection_name" {
  description = "collection name to trigger"
  type        = string
}

variable "bigquery_table_fullname" {
  description = "bigquery table fullname (project.dataset.table)"
  type        = string
}

variable "service_account_email" {
  description = "service account email"
  type        = string
}
