# PickStream Infrastructure Setup Guide

Complete guide for provisioning GKE infrastructure for the PickStream application.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [GCP Configuration](#gcp-configuration)
4. [Terraform Deployment](#terraform-deployment)
5. [kubectl Configuration](#kubectl-configuration)
6. [Verification](#verification)
7. [GitHub Actions Setup](#github-actions-setup)
8. [Next Steps](#next-steps)

---

## Prerequisites

### Required Tools

Install the following tools before starting:

| Tool | Version | Installation |
|------|---------|--------------|
| Terraform | >= 1.5.0 | [Download](https://www.terraform.io/downloads) |
| gcloud CLI | >= 450.0.0 | [Download](https://cloud.google.com/sdk/docs/install) |
| kubectl | >= 1.28.0 | [Download](https://kubernetes.io/docs/tasks/tools/) |
| Git | Latest | [Download](https://git-scm.com/downloads) |

### Required Accounts

- **Google Cloud Platform**: Account with billing enabled
- **GitHub**: Account for repository access

### Required Permissions

Your GCP account needs these roles:
- Compute Admin
- Kubernetes Engine Admin
- Service Account Admin
- Security Admin

---

## Initial Setup

### 1. Clone Repository

```bash
git clone https://github.com/gcpt0801/pickstream-infrastructure.git
cd pickstream-infrastructure
```

### 2. Set Environment Variables

```bash
export PROJECT_ID="your-gcp-project-id"
export REGION="us-central1"
export ENVIRONMENT="dev"
```

---

## GCP Configuration

### 1. Authenticate to GCP

```bash
# Login with your user account
gcloud auth login

# Set application default credentials
gcloud auth application-default login

# Set active project
gcloud config set project $PROJECT_ID
```

### 2. Enable Required APIs

```bash
# Enable Compute Engine API
gcloud services enable compute.googleapis.com

# Enable Kubernetes Engine API
gcloud services enable container.googleapis.com

# Enable Cloud Resource Manager API
gcloud services enable cloudresourcemanager.googleapis.com

# Enable IAM API
gcloud services enable iam.googleapis.com

# Enable Cloud Storage API (for Terraform state)
gcloud services enable storage-api.googleapis.com

# Verify enabled services
gcloud services list --enabled
```

### 3. Create GCS Bucket for Terraform State

```bash
# Create bucket with unique name
export STATE_BUCKET="pickstream-tfstate-${PROJECT_ID}"

gsutil mb -p $PROJECT_ID -l $REGION gs://$STATE_BUCKET

# Enable versioning for safety
gsutil versioning set on gs://$STATE_BUCKET

# Set lifecycle policy to delete old versions after 30 days
cat > lifecycle.json <<EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {
          "numNewerVersions": 5
        }
      }
    ]
  }
}
EOF

gsutil lifecycle set lifecycle.json gs://$STATE_BUCKET
rm lifecycle.json

# Verify bucket
gsutil ls -L gs://$STATE_BUCKET
```

### 4. Create Service Account for Terraform

```bash
# Create service account
gcloud iam service-accounts create terraform-sa \
    --display-name="Terraform Service Account" \
    --description="Service account for Terraform infrastructure provisioning"

# Get service account email
export SA_EMAIL="terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com"

# Grant required roles
declare -a roles=(
    "roles/compute.admin"
    "roles/container.admin"
    "roles/iam.serviceAccountAdmin"
    "roles/iam.serviceAccountUser"
    "roles/storage.admin"
    "roles/resourcemanager.projectIamAdmin"
)

for role in "${roles[@]}"; do
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:$SA_EMAIL" \
        --role="$role"
done

# Create and download key
gcloud iam service-accounts keys create ~/terraform-sa-key.json \
    --iam-account=$SA_EMAIL

echo "✅ Service account created and key saved to ~/terraform-sa-key.json"
echo "⚠️  Keep this file secure and never commit it to Git!"
```

---

## Terraform Deployment

### 1. Configure Environment

```bash
cd terraform/environments/dev

# Create terraform.tfvars file
cat > terraform.tfvars <<EOF
project_id     = "$PROJECT_ID"
region         = "$REGION"
cluster_name   = "pickstream-cluster"
environment    = "$ENVIRONMENT"

# Node pool configuration
system_node_pool_machine_type = "e2-medium"
system_node_pool_min_count    = 1
system_node_pool_max_count    = 3

app_node_pool_machine_type = "e2-standard-2"
app_node_pool_min_count    = 2
app_node_pool_max_count    = 5

# Use preemptible nodes for dev (cost savings)
use_preemptible_nodes = true
EOF

# Create backend configuration
cat > backend.tf <<EOF
terraform {
  backend "gcs" {
    bucket = "$STATE_BUCKET"
    prefix = "dev/terraform/state"
  }
}
EOF
```

### 2. Initialize Terraform

```bash
# Set credentials
export GOOGLE_APPLICATION_CREDENTIALS=~/terraform-sa-key.json

# Initialize Terraform
terraform init

# Verify initialization
terraform version
terraform providers
```

### 3. Plan Infrastructure

```bash
# Review what will be created
terraform plan

# Save plan to file
terraform plan -out=tfplan

# Review plan details
terraform show tfplan
```

### 4. Apply Infrastructure

```bash
# Apply infrastructure changes
terraform apply tfplan

# Or apply directly (with confirmation prompt)
terraform apply

# Apply without confirmation (use with caution)
terraform apply -auto-approve
```

This will create:
- VPC network with private subnets
- GKE Standard cluster with Workload Identity
- System node pool (1-3 nodes)
- Application node pool (2-5 nodes)
- Cloud NAT for egress traffic
- Firewall rules
- Service accounts and IAM bindings

**Expected deployment time**: 10-15 minutes

---

## kubectl Configuration

### 1. Get Cluster Credentials

```bash
# Get cluster name and region from Terraform outputs
export CLUSTER_NAME=$(terraform output -raw cluster_name)
export CLUSTER_REGION=$(terraform output -raw cluster_region)

# Configure kubectl
gcloud container clusters get-credentials $CLUSTER_NAME \
    --region=$CLUSTER_REGION \
    --project=$PROJECT_ID

# Verify connection
kubectl cluster-info
kubectl config current-context
```

### 2. Alternative: Use Setup Script

```bash
# From repository root
cd ../../..
./scripts/setup-kubectl.sh dev $PROJECT_ID
```

---

## Verification

### 1. Verify Cluster Status

```bash
# Check cluster details
gcloud container clusters describe $CLUSTER_NAME \
    --region=$CLUSTER_REGION \
    --format="table(name,status,currentMasterVersion,location)"

# Check node pools
gcloud container node-pools list \
    --cluster=$CLUSTER_NAME \
    --region=$CLUSTER_REGION
```

### 2. Verify Nodes

```bash
# List all nodes
kubectl get nodes -o wide

# Check node resource usage
kubectl top nodes

# Get node details
kubectl describe nodes
```

### 3. Verify System Pods

```bash
# Check system namespace pods
kubectl get pods -n kube-system

# Check if all pods are running
kubectl get pods -A | grep -v Running
```

### 4. Run Full Verification

```bash
# From repository root
./scripts/verify-cluster.sh dev $PROJECT_ID
```

This script checks:
- ✅ Cluster accessibility
- ✅ Node pool configuration
- ✅ Node health and resources
- ✅ System pods status
- ✅ Workload Identity
- ✅ Binary Authorization
- ✅ Network policies
- ✅ Storage classes
- ✅ RBAC configuration

---

## GitHub Actions Setup

### 1. Create GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Create these secrets:

| Secret Name | Value | How to Get |
|-------------|-------|------------|
| `GCP_PROJECT_ID` | Your GCP project ID | `echo $PROJECT_ID` |
| `GCP_SA_KEY` | Service account JSON key | `cat ~/terraform-sa-key.json` |
| `TF_STATE_BUCKET` | GCS bucket name | `echo $STATE_BUCKET` |

### 2. Test Workflows

#### Test Plan Workflow

```bash
# Create a new branch
git checkout -b test-infrastructure

# Make a small change
echo "# Test" >> terraform/environments/dev/README.md

# Commit and push
git add .
git commit -m "Test infrastructure change"
git push origin test-infrastructure

# Create PR on GitHub - this will trigger terraform-plan workflow
```

#### Test Apply Workflow

```bash
# After PR is approved and merged, manually trigger apply workflow
# Go to: Actions → Terraform Apply → Run workflow
# Select environment: dev
```

---

## Next Steps

### 1. Deploy Application

Now that infrastructure is ready, deploy the application:

```bash
# Clone application repository
git clone https://github.com/gcpt0801/pickstream-app.git
cd pickstream-app

# Follow the deployment guide in pickstream-app repository
```

### 2. Set Up Monitoring (Optional)

```bash
# Install Prometheus and Grafana
kubectl create namespace monitoring

# Add Prometheus Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring

# Get Grafana password
kubectl get secret -n monitoring prometheus-grafana \
    -o jsonpath="{.data.admin-password}" | base64 --decode

# Port forward to access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Access at http://localhost:3000 (username: admin)
```

### 3. Set Up Ingress Controller (Optional)

```bash
# Install Nginx Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

# Get external IP
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

### 4. Configure DNS (Optional)

```bash
# Get load balancer IP
LB_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Configure DNS A record: pickstream.yourdomain.com → $LB_IP"
```

---

## Troubleshooting

### Issue: Terraform Init Fails

```bash
# Check credentials
gcloud auth application-default print-access-token

# Verify bucket exists
gsutil ls gs://$STATE_BUCKET

# Re-initialize with debug
TF_LOG=DEBUG terraform init
```

### Issue: Cluster Creation Fails

```bash
# Check quotas
gcloud compute project-info describe --project=$PROJECT_ID

# Check API enablement
gcloud services list --enabled | grep container

# Check permissions
gcloud projects get-iam-policy $PROJECT_ID \
    --flatten="bindings[].members" \
    --filter="bindings.members:serviceAccount:$SA_EMAIL"
```

### Issue: kubectl Cannot Connect

```bash
# Re-fetch credentials
gcloud container clusters get-credentials $CLUSTER_NAME \
    --region=$CLUSTER_REGION \
    --project=$PROJECT_ID

# Check kubeconfig
kubectl config view

# Test connection
kubectl cluster-info
```

---

## Additional Resources

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)

---

**Need Help?**
- Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Open an issue in this repository
- Contact the instructor

