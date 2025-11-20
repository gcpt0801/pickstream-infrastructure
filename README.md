# PickStream Infrastructure

This repository contains Terraform configuration for provisioning Google Kubernetes Engine (GKE) infrastructure for the PickStream application.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     GCP Project                              │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                 VPC Network                            │ │
│  │  ┌──────────────────────────────────────────────────┐ │ │
│  │  │           GKE Standard Cluster                   │ │ │
│  │  │  ┌───────────────┐    ┌───────────────────────┐ │ │ │
│  │  │  │ System Pool   │    │   Application Pool    │ │ │ │
│  │  │  │ 2x e2-medium  │    │   3x e2-standard-2    │ │ │ │
│  │  │  │ (Autoscaling) │    │   (Autoscaling)       │ │ │ │
│  │  │  └───────────────┘    └───────────────────────┘ │ │ │
│  │  │                                                  │ │ │
│  │  │  Features:                                       │ │ │
│  │  │  - Workload Identity                             │ │ │
│  │  │  - Network Policy                                │ │ │
│  │  │  - Binary Authorization                          │ │ │
│  │  │  - Private Nodes                                 │ │ │
│  │  └──────────────────────────────────────────────────┘ │ │
│  │                                                        │ │
│  │  Cloud NAT  ←→  Cloud Load Balancer                   │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 📋 Prerequisites

### Required Tools
- [Terraform](https://www.terraform.io/downloads) >= 1.5.0
- [gcloud CLI](https://cloud.google.com/sdk/docs/install) >= 450.0.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/) >= 1.28.0
- [Git](https://git-scm.com/downloads)

### Required Accounts
- Google Cloud Platform account with billing enabled
- GitHub account

### Required Permissions
- GCP Project Owner or Editor
- Compute Admin
- Kubernetes Engine Admin
- Service Account Admin

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/gcpt0801/pickstream-infrastructure.git
cd pickstream-infrastructure
```

### 2. Set Up GCP Project
```bash
# Login to GCP
gcloud auth login

# Set project
export PROJECT_ID="your-gcp-project-id"
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable storage-api.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
```

### 3. Create GCS Bucket for Terraform State
```bash
export BUCKET_NAME="pickstream-tfstate-${PROJECT_ID}"
gcloud storage buckets create gs://${BUCKET_NAME} \
    --location=us-central1 \
    --uniform-bucket-level-access
```

### 4. Create Service Account
```bash
# Create service account
gcloud iam service-accounts create terraform-sa \
    --display-name="Terraform Service Account"

# Get service account email
export SA_EMAIL=$(gcloud iam service-accounts list \
    --filter="displayName:Terraform Service Account" \
    --format="value(email)")

# Grant roles
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/compute.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/container.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/storage.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/iam.serviceAccountUser"

# Create key
gcloud iam service-accounts keys create ~/gcp-key.json \
    --iam-account=$SA_EMAIL
```

### 5. Configure Terraform
```bash
cd terraform/environments/dev

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
project_id = "$PROJECT_ID"
region = "us-central1"
cluster_name = "pickstream-cluster"
environment = "dev"
EOF

# Update backend configuration
cat > backend.tf <<EOF
terraform {
  backend "gcs" {
    bucket = "$BUCKET_NAME"
    prefix = "dev/terraform/state"
  }
}
EOF
```

### 6. Deploy Infrastructure
```bash
# Initialize Terraform
terraform init

# Plan infrastructure
terraform plan

# Apply infrastructure
terraform apply

# Get cluster credentials
gcloud container clusters get-credentials pickstream-cluster \
    --region=us-central1 \
    --project=$PROJECT_ID

# Verify cluster
kubectl get nodes
kubectl cluster-info
```

## 📁 Repository Structure

```
pickstream-infrastructure/
├── terraform/
│   ├── modules/
│   │   ├── gke/              # GKE cluster module
│   │   ├── networking/       # VPC, subnets, NAT module
│   │   └── iam/              # Service accounts, IAM module
│   ├── environments/
│   │   ├── dev/              # Development environment
│   │   ├── staging/          # Staging environment
│   │   └── prod/             # Production environment
│   └── scripts/
│       ├── setup-kubectl.sh  # Configure kubectl
│       └── verify-cluster.sh # Verify cluster health
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml    # Plan on PR
│       ├── terraform-apply.yml   # Apply on merge
│       └── terraform-destroy.yml # Manual destroy
├── docs/
│   ├── SETUP.md              # Detailed setup guide
│   └── TROUBLESHOOTING.md    # Common issues
├── .gitignore
└── README.md
```

## 🔧 Module Details

### GKE Module
Creates a GKE Standard cluster with:
- **Control Plane**: Regional for high availability
- **Node Pools**:
  - System pool: 2-5 e2-medium nodes (1-2 vCPU, 4GB RAM)
  - Application pool: 3-10 e2-standard-2 nodes (2 vCPU, 8GB RAM)
- **Features**:
  - Workload Identity enabled
  - Network Policy enabled
  - Binary Authorization enabled
  - Private nodes with Cloud NAT
  - Automatic node repair and upgrade
  - Maintenance windows configured

### Networking Module
Creates VPC network with:
- Custom VPC network
- Private subnets for GKE nodes
- Cloud NAT for internet access
- Firewall rules for security
- Load balancer configuration

### IAM Module
Creates and manages:
- Kubernetes service accounts
- GCP service accounts
- Workload Identity bindings
- IAM roles and permissions

## 🌍 Environments

### Development (dev)
- **Purpose**: Development and testing
- **Node Pool**: Minimal resources
- **Cost**: ~$150/month
- **Features**: All features enabled

### Staging (staging)
- **Purpose**: Pre-production testing
- **Node Pool**: Production-like
- **Cost**: ~$250/month
- **Features**: All production features

### Production (prod)
- **Purpose**: Live application
- **Node Pool**: High availability
- **Cost**: ~$400/month
- **Features**: All features + monitoring

## 🔐 Required GitHub Secrets

Configure these secrets in your GitHub repository:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `GCP_PROJECT_ID` | GCP Project ID | `pickstream-project-123456` |
| `GCP_SA_KEY` | Service Account JSON key | `{"type": "service_account"...}` |
| `TF_STATE_BUCKET` | GCS bucket for state | `pickstream-tfstate-bucket` |

## 🔄 CI/CD Workflows

### Terraform Plan (on Pull Request)
```bash
# Triggered on PR to main
# - Runs terraform fmt check
# - Runs terraform validate
# - Runs terraform plan
# - Posts plan as PR comment
```

### Terraform Apply (on merge to main)
```bash
# Triggered on push to main
# - Runs terraform plan
# - Applies terraform changes
# - Updates infrastructure
```

### Terraform Destroy (manual)
```bash
# Manual workflow dispatch
# - Requires environment confirmation
# - Destroys all infrastructure
# - Removes cluster and resources
```

## 💰 Cost Estimation

### Monthly Costs (Development)
| Resource | Specification | Cost (USD) |
|----------|--------------|------------|
| GKE Control Plane | Regional | $0 (free) |
| System Node Pool | 2x e2-medium | ~$50 |
| App Node Pool | 3x e2-standard-2 | ~$100 |
| Load Balancer | External LB | ~$18 |
| Network Egress | 100GB/month | ~$12 |
| Persistent Disks | 100GB SSD | ~$17 |
| **Total** | | **~$197/month** |

### Cost Optimization Tips
1. Use preemptible nodes for dev/staging
2. Enable cluster autoscaler
3. Set appropriate resource limits
4. Use regional (not zonal) clusters
5. Monitor and optimize disk usage

## 🔍 Verify Deployment

```bash
# Check cluster status
gcloud container clusters list

# Get cluster credentials
gcloud container clusters get-credentials pickstream-cluster \
    --region=us-central1 \
    --project=$PROJECT_ID

# Verify nodes
kubectl get nodes
kubectl top nodes

# Check cluster info
kubectl cluster-info
kubectl get componentstatuses

# Verify workload identity
gcloud iam service-accounts list
```

## 🧹 Cleanup

### Option 1: Using Terraform
```bash
cd terraform/environments/dev
terraform destroy
```

### Option 2: Using gcloud
```bash
# Delete cluster
gcloud container clusters delete pickstream-cluster \
    --region=us-central1 \
    --quiet

# Delete VPC network
gcloud compute networks delete pickstream-network --quiet

# Delete service account
gcloud iam service-accounts delete $SA_EMAIL --quiet
```

## 📚 Additional Resources

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)

## 🤝 Contributing

This is an educational project. Students can:
1. Fork the repository
2. Create feature branch
3. Make changes
4. Submit pull request

## 📝 License

MIT License - See LICENSE file

## 👥 Maintainers

- Instructor: @gcpt0801

---

**Note**: This infrastructure is designed for educational purposes. For production deployments, additional security hardening and monitoring should be implemented.
