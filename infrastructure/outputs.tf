output "artifact_registry" {
  value = google_artifact_registry_repository.insight_agent.name
}

output "cloud_run_url" {
  value = google_cloud_run_service.insight_agent.status[0].url
}

output "state_bucket" {
  value = google_storage_bucket.tf_state.name
}

output "service_account_email" {
  value = google_service_account.insight_agent.email
}