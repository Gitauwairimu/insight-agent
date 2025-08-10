# Insight Agent Deployment

## Architecture Overview

This project deploys a containerized **Insight Agent** application on Google Cloud Platform (GCP) using **Cloud Run**. Infrastructure is provisioned and managed with **Terraform** for repeatability and automation.

### GCP Services Used

- **Cloud Run**: Fully managed serverless platform to run the containerized Insight Agent service.
- **Artifact Registry**: Stores Docker container images securely in a private registry.
- **Cloud Storage (GCS)**: Used as a backend bucket to store Terraform state files, enabling remote state management and collaboration.
- **Cloud Build**: (Optional) Could be used to automate container image builds.
- **IAM (Identity and Access Management)**: Manages permissions for service accounts and Cloud Run access.
- **Service Usage API**: Manages enabling/disabling of required Google APIs.
  
---

### High-Level Architecture Diagram


---

### How It Works

1. **Docker Image Build & Push:** The Insight Agent app is containerized and pushed to the Artifact Registry.
2. **Terraform Infrastructure Provisioning:** Terraform provisions the Cloud Run service, service accounts, Artifact Registry repository, and remote state bucket.
3. **Cloud Run Deployment:** Cloud Run pulls the container image and deploys the service.
4. **IAM Setup:** Public access is granted via IAM roles to allow unauthenticated invocations.
5. **State Management:** Terraform remote state is stored in a Google Cloud Storage bucket to enable collaboration and safe state locking.

---

This setup allows for a scalable, serverless deployment of the Insight Agent with fully automated infrastructure provisioning and deployment via Terraform and GitHub Actions CI/CD.


## Setup

Follow these steps to set up the project and deploy it on your Google Cloud Platform (GCP) account.

### Prerequisites

- A Google Cloud Platform project with billing enabled.
- The following GCP APIs enabled in your project:
  - Cloud Run API
  - Artifact Registry API
  - Cloud Storage API
  - Cloud Build API
  - IAM API
  - Service Usage API
- [Terraform](https://www.terraform.io/downloads) installed locally (version 1.6.6 or later recommended).
- [Docker](https://docs.docker.com/get-docker/) installed locally.
- A Google Cloud service account with the following permissions:
  - `roles/run.admin`
  - `roles/storage.admin`
  - `roles/artifactregistry.admin`
  - `roles/cloudbuild.builds.editor`
  - `roles/iam.serviceAccountUser`
  - `roles/iam.serviceAccountAdmin`
  - `roles/serviceusage.apiKeysViewer`
  - `roles/serviceusage.serviceUsageAdmin`

### 1. Create a Service Account and Download Credentials

1. In the [Google Cloud Console](https://console.cloud.google.com/iam-admin/serviceaccounts), create a new service account (e.g., `insight-agent-deployer`).
2. Assign the required roles listed above to this service account.
3. Generate a JSON key for this service account and download it.  
4. **Important:** Do **not** commit this key to your repository.

### 2. Store Secrets Securely

- If using GitHub Actions, add the following secrets in your repository settings under **Settings > Secrets and variables > Actions**:
  - `GCP_PROJECT_ID`: Your Google Cloud project ID.
  - `GCP_SA_KEY`: The entire JSON content of your service account key file.

- Locally, you can set environment variables or provide a path to your key file for Terraform and gcloud authentication.

### 3. Configure Terraform Variables

Terraform requires the following variables:

- `project_id`: Your GCP project ID.
- `region`: GCP region to deploy resources (e.g., `us-central1`).
- `credentials_file`: Path to your downloaded service account JSON key.
- `image_tag`: Docker image tag (usually the commit SHA or `latest`).

You can provide these as command-line variables or create a `terraform.tfvars` file with:

```hcl
project_id       = "your-project-id"
region           = "us-central1"
credentials_file = "/path/to/your/service-account-key.json"
image_tag        = "latest"


### 4. Initialize and Apply Terraform

cd infrastructure
terraform init
terraform apply -auto-approve \
  -var="project_id=your-project-id" \
  -var="region=us-central1" \
  -var="credentials_file=/path/to/service-account-key.json" \
  -var="image_tag=latest"

### 5. Build and Push Docker Image

cd app
docker build -t us-central1-docker.pkg.dev/your-project-id/insight-agent/insight-agent:latest .
docker push us-central1-docker.pkg.dev/your-project-id/insight-agent/insight-agent:latest

### 6. Deploy Cloud Run Service

Run Terraform apply again to deploy the Cloud Run service using the newly pushed Docker image:

cd infrastructure
terraform apply -auto-approve \
  -var="project_id=your-project-id" \
  -var="region=us-central1" \
  -var="credentials_file=/path/to/service-account-key.json" \
  -var="image_tag=latest"
