resource "google_service_account" "f2b" {
  account_id   = "${var.basename}-f2b"
  display_name = "Firestore to BigQuery Service Account"
}

resource "google_bigquery_dataset_iam_binding" "f2b" {
  dataset_id = var.dataset_id
  role       = "roles/bigquery.dataEditor"

  members = [
    "serviceAccount:${google_service_account.f2b.email}",
  ]
}

resource "google_cloud_run_service_iam_member" "f2b_invoker" {
  location = google_cloud_run_v2_service.f2b.location
  service  = google_cloud_run_v2_service.f2b.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.f2b.email}"
}

resource "google_project_iam_member" "f2b_event_receiver" {
  project = local.project
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.f2b.email}"
}

resource "google_service_account_iam_member" "pubsub_to_f2b" {
  service_account_id = google_service_account.f2b.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:service-${local.project_number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}
