# infrastructure/main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }

  # Initial local state (will migrate to GCS later)
  backend "local" {
    path = ".terraform/terraform.tfstate"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ========================
# 1. STATE STORAGE BUCKET
# ========================
resource "google_storage_bucket" "tf_state" {
  name                        = "${var.project_id}-tfstate-${random_id.bucket_suffix.hex}"
  location                    = var.region
  force_destroy               = false
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# ========================
# 2. REQUIRED APIs
# ========================
resource "google_project_service" "required_apis" {
  for_each = toset([
    "storage.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "iam.googleapis.com",
    "serviceusage.googleapis.com"
  ])
  service            = each.key
  disable_on_destroy = false
}

# ========================
# 3. ARTIFACT REGISTRY
# ========================
resource "google_artifact_registry_repository" "insight_agent" {
  repository_id = "insight-agent" 
  location      = var.region      
  format        = "DOCKER"        
  description   = "Stores Insight Agent container images"
  
  labels = {
    environment = "dev"
  }

  depends_on = [
    google_project_service.required_apis
  ]
}

# ========================
# 4. SERVICE ACCOUNT
# ========================
resource "google_service_account" "insight_agent" {
  account_id   = "insight-agent-sa"
  display_name = "Insight Agent Service Account"
  description  = "Identity for Cloud Run service"

  depends_on = [
    google_project_service.required_apis
  ]
}

# Minimal IAM roles for Cloud Run SA
resource "google_project_iam_member" "cloud_run_roles" {
  for_each = toset([
    "roles/artifactregistry.reader",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter"
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.insight_agent.email}"

  depends_on = [
    google_service_account.insight_agent
  ]
}

# ========================
# 5. CLOUD RUN SERVICE
# ========================
resource "google_cloud_run_service" "insight_agent" {
  name     = "insight-agent"
  location = var.region
  
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
      timeout_seconds     = 300
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_artifact_registry_repository.insight_agent,
    google_project_iam_member.cloud_run_roles
  ]
}

# ========================
# 6. ACCESS CONTROL
# ========================
resource "google_cloud_run_service_iam_member" "public_access" {
  location = google_cloud_run_service.insight_agent.location
  service  = google_cloud_run_service.insight_agent.name
  role     = "roles/run.invoker"
  member   = "allUsers"

  depends_on = [
    google_cloud_run_service.insight_agent
  ]
}
