
# Deployment Runbook: Insight Agent on Google Cloud

## Overview
This runbook provides step-by-step instructions for deploying the **Insight Agent** application on **Google Cloud Run** using **Terraform** for infrastructure automation.

---

## Prerequisites
- ✅ Google Cloud Account (with billing enabled)  
- ✅ Project Owner or Editor permissions  
- ✅ Terraform v1.6.6+ installed  
- ✅ gcloud CLI configured (`gcloud init`)  
- ✅ GitHub/GitLab (for CI/CD, if applicable)  

---

```bash 
## Step 1: Set Up Google Cloud Project

### 1.1 Create or Select a GCP Project
Run the following commands to create and set your GCP project:


gcloud projects create PROJECT_ID --name="Insight Agent"
gcloud config set project PROJECT_ID

Replace [PROJECT_ID] with your desired project name.
1.2 Enable Billing

    Go to Google Cloud Console > Billing

    Link your project to a billing account

Step 2: Enable Required APIs

Run the following command to enable necessary APIs:
bash

gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  storage.googleapis.com \
  cloudbuild.googleapis.com \
  iam.googleapis.com \
  serviceusage.googleapis.com

Step 3: Create & Configure Service Account
3.1 Create a Service Account
bash

gcloud iam service-accounts create insight-agent-deployer \
  --display-name="Insight Agent Deployer"

3.2 Assign Required IAM Roles
bash

gcloud projects add-iam-policy-binding [PROJECT_ID] \
  --member="serviceAccount:insight-agent-deployer@[PROJECT_ID].iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding [PROJECT_ID] \
  --member="serviceAccount:insight-agent-deployer@[PROJECT_ID].iam.gserviceaccount.com" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding [PROJECT_ID] \
  --member="serviceAccount:insight-agent-deployer@[PROJECT_ID].iam.gserviceaccount.com" \
  --role="roles/artifactregistry.admin"

3.3 Generate & Download Service Account Key
bash

gcloud iam service-accounts keys create key.json \
  --iam-account=insight-agent-deployer@[PROJECT_ID].iam.gserviceaccount.com

⚠️ Do not commit key.json to version control!
Step 4: Deploy Using Terraform
4.1 Clone the Repository
bash

git clone https://github.com/your-repo/insight-agent.git
cd insight-agent

4.2 Initialize Terraform
bash

cd infrastructure
terraform init

4.3 Apply Infrastructure
bash

terraform apply -auto-approve \
  -var="project_id=[PROJECT_ID]" \
  -var="credentials_file=key.json" \
  -var="region=us-central1"

Step 5: Verify Deployment
5.1 Get Cloud Run URL
bash

gcloud run services describe insight-agent \
  --platform managed \
  --region us-central1 \
  --format "value(status.url)"

5.2 Test the API
bash

curl -X POST https://[CLOUD_RUN_URL]/analyze \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello World"}'

Expected Response:
json

{
  "original_text": "Hello World",
  "word_count": 2,
  "character_count": 11
}

Step 6: Clean Up (Avoid Costs!)
6.1 Destroy Terraform Resources
bash

terraform destroy -auto-approve \
  -var="project_id=[PROJECT_ID]" \
  -var="credentials_file=key.json"

6.2 Manual Cleanup (If Needed)

    Delete the Terraform state bucket:
    bash

gsutil rm -r gs://[PROJECT_ID]-tfstate-insight_agent

Disable APIs (if no longer needed):
bash

    gcloud services disable run.googleapis.com artifactregistry.googleapis.com

Troubleshooting
Issue	Solution
PERMISSION_DENIED	Ensure APIs are enabled & SA has correct roles
Error: Storage Bucket exists	Import existing bucket with terraform import
Image not found in Artifact Registry	Rebuild & push Docker image
Conclusion

✅ Deployed Insight Agent on Cloud Run
✅ Infrastructure managed via Terraform
✅ Tested API endpoint
✅ Resources cleaned up to avoid costs

🚀 Next Steps:

    Set up CI/CD (GitHub Actions/Cloud Build)

    Configure monitoring (Cloud Logging/Monitoring)

    Add custom domain (if needed)

This runbook ensures a repeatable, automated deployment while minimizing manual steps. Adjust variables (region, project_id) as needed.