output "project_id" {
  value = data.google_project.project.project_id
}

output "region" {
  value = data.google_client_config.current.region
}

output "zone" {
  value = data.google_client_config.current.zone
}
