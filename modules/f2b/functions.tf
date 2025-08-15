resource "google_cloud_run_v2_service" "f2b" {
  name     = "${var.basename}-f2b"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  template {
    service_account = google_service_account.f2b.email

    containers {
      image = local.repo_image_uri

      env {
        name = "EXPORT_CONFIG"
        value = jsonencode({
          rules = {
            for k, rule in var.rules : k => merge(
              rule,
              {
                topic = module.f2b_pubsub[k].pubsub_topic_name
              },
            )
          }
        })
      }
    }
  }
}
