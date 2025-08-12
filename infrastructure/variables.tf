# Document the infrastructure variables expected in project

# The project id
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

# The region to deploy with a default
variable "region" {
  description = "The GCP region to deploy resources"
  type        = string
  default     = "us-central1"
}

# Expect an image tag
variable "image_tag" {
  description = "The container image tag to deploy"
  type        = string
  default     = "latest"
}

# A credential file to hold the service account key
variable "credentials_file" {
  description = "Path to the GCP service account JSON key file"
  type        = string
}