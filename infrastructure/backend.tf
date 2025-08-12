# Give the bucket expected to hold state
terraform {
  backend "gcs" {
    bucket = "my-project-tfstate-insight_agent"
    prefix = "terraform/state"
  }
}