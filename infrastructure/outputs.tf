# infrastructure/outputs.tf
output "artifact_registry_repository" {
  value = google_artifact_registry_repository.insight_agent.name
}

output "service_account_email" {
  value = google_service_account.insight_agent.email
}

output "cloud_run_url" {
  value = google_cloud_run_service.insight_agent.status[0].url
}