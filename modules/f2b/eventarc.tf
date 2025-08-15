resource "google_eventarc_trigger" "trigger" {
  for_each = var.rules

  name     = "${var.basename}-f2b-${lower(each.key)}"
  location = var.region

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.firestore.document.v1.written"
  }

  matching_criteria {
    attribute = "database"
    value     = var.firestore_database_name
  }

  matching_criteria {
    attribute = "document"
    value     = "${each.key}/{id}"
    operator  = "match-path-pattern"
  }

  event_data_content_type = "application/protobuf"

  destination {
    cloud_run_service {
      service = google_cloud_run_v2_service.f2b.name
      region  = google_cloud_run_v2_service.f2b.location
    }
  }

  service_account = google_service_account.f2b.email

  depends_on = [
    google_cloud_run_service_iam_member.f2b_invoker,
    google_project_iam_member.f2b_event_receiver,
  ]
}
