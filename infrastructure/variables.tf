# infrastructure/variables.tf
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources"
  type        = string
  default     = "us-central1"
}

variable "image_tag" {
  description = "The container image tag to deploy"
  type        = string
  default     = "latest"
}


variable "credentials_file" {
  description = "Path to the GCP service account JSON key file"
  type        = string
}