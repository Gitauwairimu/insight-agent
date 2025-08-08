terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_service" "required_apis" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com"
  ])
  service = each.key
}

resource "google_artifact_registry_repository" "insight_agent" {
  name        = "insight-agent"
  location    = var.region
  format      = "DOCKER"
  depends_on  = [google_project_service.required_apis]
}

resource "google_service_account" "insight_agent" {
  account_id   = "insight-agent-sa"
  display_name = "Cloud Run Insight Agent Service Account"
}

resource "google_cloud_run_service" "insight_agent" {
  name     = "insight-agent"
  location = var.region
  
  template {
    spec {
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/insight-agent/insight-agent:${var.image_tag}"
      }
      service_account_name = google_service_account.insight_agent.email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [google_project_service.required_apis]
}

resource "google_cloud_run_service_iam_member" "noauth" {
  location = google_cloud_run_service.insight_agent.location
  service  = google_cloud_run_service.insight_agent.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}