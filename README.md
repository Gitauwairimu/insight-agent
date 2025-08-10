# Insight Agent - Cloud Run Deployment

## Architecture Overview

This solution deploys a containerized application to Google Cloud Run with supporting GCP services:
┌───────────────────────────────────────────────────────────────┐
│ GCP Project │
│ │
│ ┌─────────────┐ ┌─────────────┐ ┌──────────────────┐ │
│ │ Artifact │ │ Cloud Run │ │ Service Account │ │
│ │ Registry │◄───┤ Service ├───►│ (insight-agent) │ │
│ └─────────────┘ └─────────────┘ └──────────────────┘ │
│ ▲ │
│ │ │
│ ┌─────┴─────┐ │
│ │ Cloud │ │
│ │ Storage │ │
│ │ (TF State)│ │
│ └───────────┘ │
└───────────────────────────────────────────────────────────────┘

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

## Prerequisites

- Google Cloud Project with billing enabled
- Owner permissions on the GCP project
- Docker installed locally (for development)
- Terraform v1.6.6+
- gcloud CLI configured with credentials

## Setup Instructions

### 1. First-Time Deployment
```bash
# Clone repository
git clone https://github.com/your-repo/insight-agent.git
cd insight-agent

# Initialize infrastructure
cd infrastructure
terraform init

# Deploy with GitHub Actions
# (Configure secrets in GitHub first)

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

```

### 4. Initialize and Apply Terraform

```hcl
cd infrastructure
terraform init
terraform apply -auto-approve \
  -var="project_id=your-project-id" \
  -var="region=us-central1" \
  -var="credentials_file=/path/to/service-account-key.json" \
  -var="image_tag=latest"
```

### 5. Build and Push Docker Image

```hcl
cd app
docker build -t us-central1-docker.pkg.dev/your-project-id/insight-agent/insight-agent:latest .
docker push us-central1-docker.pkg.dev/your-project-id/insight-agent/insight-agent:latest
```

### 6. Deploy Cloud Run Service

Run Terraform apply again to deploy the Cloud Run service using the newly pushed Docker image:

```hcl
cd infrastructure
terraform apply -auto-approve \
  -var="project_id=your-project-id" \
  -var="region=us-central1" \
  -var="credentials_file=/path/to/service-account-key.json" \
  -var="image_tag=latest"
```



## Design Decisions

### Why Cloud Run?

- **Serverless and Fully Managed:** Cloud Run abstracts away infrastructure management, letting you focus solely on your application code.
- **Scalability:** It automatically scales based on incoming traffic, handling spikes without manual intervention.
- **Cost Efficiency:** You pay only for the compute time your container uses, reducing idle resource costs.
- **Simple Deployment:** Integrates seamlessly with container registries and CI/CD pipelines like GitHub Actions.
- **Supports Standard Containers:** No vendor lock-in with proprietary runtime — any container image works.

### Security Management

- **Service Account with Least Privilege:** A dedicated service account is created with only necessary IAM roles, limiting access to required resources.
- **IAM Role Assignments:** Roles like `roles/run.invoker` are granted to `allUsers` only when public access is needed, otherwise access is tightly controlled.
- **Terraform Lifecycle Management:** Resources like storage buckets and service accounts use `prevent_destroy` and `ignore_changes` to avoid accidental deletions or modifications.
- **Secrets Management:** Sensitive credentials (e.g., service account keys) are kept out of the codebase and stored securely as GitHub Actions secrets or local environment variables.
- **Remote State Storage:** Terraform state is stored securely in a Google Cloud Storage bucket with versioning and access control, ensuring state integrity and collaboration safety.




## How The CI/CD Pipeline Work

The CI/CD pipeline automates the build, deployment, and verification of the Insight Agent application to Google Cloud Run, ensuring consistent and repeatable releases.

### Workflow Trigger

- The pipeline is triggered on every push to the `main` branch of the repository.

### Key Steps in the Pipeline

1. **Checkout Code**
   - The latest code is checked out from the repository using `actions/checkout`.

2. **Authenticate to Google Cloud**
   - Uses the `google-github-actions/auth` action to authenticate with GCP using a service account key stored securely in GitHub Secrets.

3. **Set Up Google Cloud SDK (gcloud)**
   - Installs and configures the `gcloud` CLI for further Google Cloud operations.

4. **Set Up Terraform**
   - Installs Terraform (version 1.6.6) for infrastructure provisioning.

5. **Terraform Initialization**
   - Cleans any previous Terraform local state files and initializes Terraform in the `infrastructure` directory.

6. **Ensure Terraform Remote State Bucket Exists**
   - Checks if the Google Cloud Storage bucket for Terraform remote state exists; creates it if missing.

7. **Bootstrap Remote State**
   - Imports existing Terraform-managed resources into the state if they aren’t tracked yet.
   - Applies initial Terraform changes to enable required APIs and provision the remote state bucket.

8. **Configure Remote Backend**
   - Configures Terraform to use the remote state bucket, migrating local state if necessary.

9. **Authenticate Docker for Artifact Registry**
   - Configures Docker authentication to push container images to Google Artifact Registry.

10. **Build & Push Docker Image**
    - Builds the Insight Agent Docker container tagged with the GitHub commit SHA.
    - Pushes the image to Artifact Registry.

11. **Deploy Infrastructure with Terraform**
    - Writes service account credentials locally.
    - Imports existing cloud resources to Terraform state to avoid duplication errors.
    - Runs `terraform plan` for preview and then `terraform apply` to create/update resources.
    - Deploys the Cloud Run service referencing the newly pushed container image.

12. **Verify Deployment**
    - Fetches the deployed Cloud Run service URL from Terraform outputs.
    - Sends a test HTTP request to verify the service is responding correctly.

---

This pipeline ensures infrastructure and application code are deployed together reliably, minimizing manual intervention and improving deployment speed and consistency.
