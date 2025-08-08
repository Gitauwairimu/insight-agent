terraform {
  backend "gcs" {
    bucket = "your-bootstrap-tf-state-bucket" # Set manually
    prefix = "terraform/state"
  }
}
