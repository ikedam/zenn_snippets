resource "google_pubsub_topic" "cdc" {
  name = "${var.basename}-f2b-${lower(var.collection_name)}"

  message_retention_duration = "3600s"
}

resource "google_pubsub_subscription" "cdc" {
  name  = "${var.basename}-f2b-${lower(var.collection_name)}"
  topic = google_pubsub_topic.cdc.name

  message_retention_duration = "3600s"

  expiration_policy {
    # never expire
    ttl = ""
  }

  bigquery_config {
    table               = var.bigquery_table_fullname
    use_table_schema    = true
    drop_unknown_fields = true

    service_account_email = var.service_account_email
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "300s"
  }
}

resource "google_pubsub_topic_iam_member" "f2b" {
  topic  = google_pubsub_topic.cdc.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${var.service_account_email}"
}
