module "f2b" {
  source = "./modules/f2b"

  providers = {
    google  = google
    archive = archive
    docker  = docker
  }

  basename                = var.basename
  region                  = var.region
  firestore_database_name = google_firestore_database.database.name
  dataset_id              = google_bigquery_dataset.demo.dataset_id
  image_repository_uri    = "${local.registry_uri}/f2b"

  rules = {
    Testdata = {
      table = google_bigquery_table.testdata.table_id
      fields = [
        for field in jsondecode(google_bigquery_table.testdata.schema) :
        field.name
      ]
    },
  }

  depends_on = [
    google_project_service.artifactregistry,
    google_project_service.pubsub,
    google_project_service.eventarc,
  ]
}
