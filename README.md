# Insight Agent - Cloud Run Deployment

## Architecture Overview

This solution deploys a containerized application to Google Cloud Run with supporting GCP services. The final Docker image is optimized for size at just below **60.0 MB**, enabling fast deployment and cold starts.

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
- Terraform v1.6.6+
- gcloud CLI configured with credentials

## Setup Instructions

### 1. First-Time Deployment

## Setup and Deployment Instructions On Google Cloud

Follow these steps to set up the necessary credentials and deploy the Insight Agent project from scratch on Google Cloud, **without committing any secrets to the repository**.

---

### 1. Create a Google Cloud Project (if you don’t have one)

- Go to [Google Cloud Console](https://console.cloud.google.com/).
- Create a new project or select an existing one.
- Ensure billing is enabled for the project.

---

### 2. Enable Required Google Cloud APIs

Enable the following APIs in your project (via Console > APIs & Services > Library):

- Cloud Run API
- Artifact Registry API
- Cloud Storage API
- Cloud Build API
- IAM API
- Service Usage API

> ⚠️ **Permission Errors?**  
> If you encounter `PERMISSION_DENIED` errors during deployment:  
> 1. Double-check that **all required APIs are enabled** in your project.  
> 2. Ensure your service account has the [required IAM roles](#3-create-a-service-account-with-required-permissions).  
> 3. APIs can take a few minutes to propagate—wait and retry if needed.  

---

### 3. Create a Service Account with Required Permissions

1. Navigate to **IAM & Admin > Service Accounts** in the Cloud Console.
2. Click **Create Service Account** and name it (e.g., `insight-agent-deployer`).
3. Grant the following roles to the service account:
   - `roles/run.admin`
   - `roles/storage.admin`
   - `roles/artifactregistry.admin`
   - `roles/iam.serviceAccountAdmin`
   - `roles/serviceusage.consumer`
4. Click **Done** to create the account.

---

### 4. Create and Download Service Account Key

1. In the Service Accounts list, click on your newly created account.
2. Go to the **Keys** tab.
3. Click **Add Key > Create New Key**.
4. Choose **JSON** format and click **Create**.
5. Save the downloaded JSON file securely.  
   **Do not commit this file to source control.**

---

### 5. Store Secrets Securely (For Cloud-Based CI/CD)

- If you plan to use GitHub Actions or another CI/CD system, upload the following secrets to your repository’s secret storage (e.g., GitHub Secrets):
  - `GCP_PROJECT_ID`: Your Google Cloud project ID.
  - `GCP_SA_KEY`: Contents of the JSON key file (copy-paste entire JSON).

---

### 6. Set Environment Variables or Configure Access on Cloud Shell (Optional)

If you prefer to deploy manually or from Cloud Shell:

```bash
# Clone repository
git clone https://github.com/Gitauwairimu/insight-agent.git
cd insight-agent
```

- Ensure the environment variables in - insight-agent/.github/workflows/deploy.yml:
- As set in the repository’s secret storage variables


```hcl
PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
GOOGLE_CREDENTIALS: ${{ secrets.GCP_SA_KEY }}

```



### 3. Configure Terraform Variables

Terraform requires the following variables set with region of your choice in infrastructure/variables.tf:

```hcl
region           = "us-central1"

```
Trigger the workflow by pushing the changes to git on main branch.

## Usage and Testing

Once the Insight Agent service is deployed on Cloud Run, a Url is generated, follow these steps to use and test it:

---

### Usage

- The service exposes a REST API endpoint at:

```hcl
https://<your-cloud-run-url>/analyze

```

- To analyze text, send a POST request with JSON payload:


```json
{
  "text": "Your text to analyze here"
}

```
Example using curl

```hcl
curl -X POST https://<your-cloud-run-url>/analyze \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello Insight Agent!"}'
```

Expected Response if Successiful

```hcl
{
  "original_text": "Testing deployment",
  "word_count": 2,
  "character_count": 18
}

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
