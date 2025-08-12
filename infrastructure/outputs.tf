# Description: The name of the Google Artifact Registry repository created for storing Insight 
output "artifact_registry" {
  value = google_artifact_registry_repository.insight_agent.name
}

# Description: The public URL endpoint for the deployed Insight Agent Cloud Run service.
output "cloud_run_url" {
  value = google_cloud_run_service.insight_agent.status[0].url
}

# Description: The name of the Google Cloud Storage bucket used for storing Terraform state files.
output "state_bucket" {
  value = google_storage_bucket.tf_state.name
}

# Description: The email address of the service account created for the Insight Agent service.
output "service_account_email" {
  value = google_service_account.insight_agent.email
}