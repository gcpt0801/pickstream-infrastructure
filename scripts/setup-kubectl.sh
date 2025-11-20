#!/bin/bash

# Setup kubectl for GKE cluster access
# Usage: ./setup-kubectl.sh [environment] [project-id]

set -e

ENVIRONMENT=${1:-dev}
PROJECT_ID=${2:-gcp-terraform-demo-474514}

echo "========================================="
echo "Setting up kubectl for GKE Cluster"
echo "========================================="
echo "Environment: $ENVIRONMENT"
echo "Project: $PROJECT_ID"
echo ""

# Navigate to terraform environment
cd "$(dirname "$0")/../terraform/environments/$ENVIRONMENT"

# Get cluster details from terraform outputs
echo "📦 Getting cluster information from Terraform..."
CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "pickstream-cluster")
CLUSTER_REGION=$(terraform output -raw cluster_region 2>/dev/null || echo "us-central1")

echo "  Cluster Name: $CLUSTER_NAME"
echo "  Region: $CLUSTER_REGION"
echo ""

# Get cluster credentials
echo "🔐 Fetching cluster credentials..."
gcloud container clusters get-credentials "$CLUSTER_NAME" \
    --region="$CLUSTER_REGION" \
    --project="$PROJECT_ID"

echo ""
echo "✅ kubectl configured successfully!"
echo ""

# Verify connection
echo "========================================="
echo "Cluster Information"
echo "========================================="
kubectl cluster-info

echo ""
echo "========================================="
echo "Cluster Nodes"
echo "========================================="
kubectl get nodes

echo ""
echo "========================================="
echo "Namespaces"
echo "========================================="
kubectl get namespaces

echo ""
echo "========================================="
echo "✅ Setup Complete!"
echo "========================================="
echo ""
echo "You can now use kubectl to interact with your cluster:"
echo "  kubectl get pods --all-namespaces"
echo "  kubectl get services --all-namespaces"
echo ""
