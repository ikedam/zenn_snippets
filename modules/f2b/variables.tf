variable "basename" {
  description = "basename of resources"
  type        = string
}

variable "region" {
  description = "region"
  type        = string
}

variable "dataset_id" {
  description = "bigquery dataset id"
  type        = string
}

variable "firestore_database_name" {
  description = "firestore database name"
  type        = string
}

variable "image_repository_uri" {
  description = "image repository uri"
  type        = string
}

variable "rules" {
  description = "rules"
  type = map(object({
    table  = string
    fields = optional(list(string))
  }))
}
