# infrastructure/main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }

  backend "gcs" {
    # Configure this with your GCS bucket details for state storage
    # bucket = "your-tf-state-bucket"
    # prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "iam.googleapis.com"
  ])
  service = each.key
  disable_on_destroy = false
}

# Artifact Registry for container images
resource "google_artifact_registry_repository" "insight_agent" {
  name        = "insight-agent"
  location    = var.region
  format      = "DOCKER"
  description = "Repository for Insight Agent container images"
  depends_on  = [google_project_service.required_apis]
}

# Service Account for Cloud Run
resource "google_service_account" "insight_agent" {
  account_id   = "insight-agent-sa"
  display_name = "Insight Agent Service Account"
  description  = "Service account for running Insight Agent on Cloud Run"
  depends_on   = [google_project_service.required_apis]
}

# IAM roles for the service account
resource "google_project_iam_member" "cloud_run_sa_roles" {
  for_each = toset([
    "roles/run.admin",
    "roles/artifactregistry.reader",
    "roles/iam.serviceAccountUser"
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.insight_agent.email}"
  depends_on = [google_service_account.insight_agent]
}

# Cloud Run Service
resource "google_cloud_run_service" "insight_agent" {
  name     = "insight-agent"
  location = var.region
  description = "Insight Agent API service"
  
  template {
    spec {
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/insight-agent/insight-agent:${var.image_tag}"
        ports {
          container_port = 8080
        }
        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }
      }
      service_account_name = google_service_account.insight_agent.email
      timeout_seconds = 300
    }

    metadata {
      annotations = {
        "run.googleapis.com/client-name" = "terraform"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_project_service.required_apis,
    google_artifact_registry_repository.insight_agent
  ]
}

# Make the service publicly accessible
resource "google_cloud_run_service_iam_member" "public_access" {
  location = google_cloud_run_service.insight_agent.location
  service  = google_cloud_run_service.insight_agent.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Output the service URL
output "service_url" {
  value = google_cloud_run_service.insight_agent.status[0].url
}