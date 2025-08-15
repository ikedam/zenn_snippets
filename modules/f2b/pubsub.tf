module "f2b_pubsub" {
  for_each = var.rules

  source = "../f2b_pubsub"

  providers = {
    google = google
  }

  basename                = var.basename
  bigquery_table_fullname = "${local.project}.${var.dataset_id}.${each.value.table}"
  collection_name         = each.key
  service_account_email   = google_service_account.f2b.email
}
