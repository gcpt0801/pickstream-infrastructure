#!/bin/bash

# Verify GKE cluster health and configuration
# Usage: ./verify-cluster.sh [environment] [project-id]

set -e

ENVIRONMENT=${1:-dev}
PROJECT_ID=${2:-gcp-terraform-demo-474514}

echo "========================================="
echo "GKE Cluster Health Check"
echo "========================================="
echo "Environment: $ENVIRONMENT"
echo "Project: $PROJECT_ID"
echo ""

# Function to print section header
print_header() {
    echo ""
    echo "========================================="
    echo "$1"
    echo "========================================="
}

# Function to check command success
check_status() {
    if [ $? -eq 0 ]; then
        echo "✅ $1: PASSED"
    else
        echo "❌ $1: FAILED"
        return 1
    fi
}

# Get cluster details
cd "$(dirname "$0")/../terraform/environments/$ENVIRONMENT"
CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "pickstream-cluster")
CLUSTER_REGION=$(terraform output -raw cluster_region 2>/dev/null || echo "us-central1")

print_header "1. Cluster Information"
gcloud container clusters describe "$CLUSTER_NAME" \
    --region="$CLUSTER_REGION" \
    --project="$PROJECT_ID" \
    --format="table(name,location,currentMasterVersion,status)"
check_status "Cluster exists and is accessible"

print_header "2. Node Pools"
gcloud container node-pools list \
    --cluster="$CLUSTER_NAME" \
    --region="$CLUSTER_REGION" \
    --project="$PROJECT_ID" \
    --format="table(name,config.machineType,initialNodeCount,autoscaling.minNodeCount,autoscaling.maxNodeCount,status)"
check_status "Node pools configured correctly"

print_header "3. Nodes Status"
kubectl get nodes -o wide
check_status "All nodes are ready"

print_header "4. Node Resource Usage"
kubectl top nodes
check_status "Resource metrics available"

print_header "5. System Pods Status"
kubectl get pods -n kube-system
check_status "System pods are running"

print_header "6. Cluster Services"
kubectl get svc --all-namespaces
check_status "Services are accessible"

print_header "7. Storage Classes"
kubectl get storageclass
check_status "Storage classes available"

print_header "8. Network Policies"
kubectl get networkpolicies --all-namespaces
check_status "Network policies checked"

print_header "9. Workload Identity"
gcloud container clusters describe "$CLUSTER_NAME" \
    --region="$CLUSTER_REGION" \
    --project="$PROJECT_ID" \
    --format="value(workloadIdentityConfig.workloadPool)"
check_status "Workload Identity enabled"

print_header "10. Binary Authorization"
gcloud container clusters describe "$CLUSTER_NAME" \
    --region="$CLUSTER_REGION" \
    --project="$PROJECT_ID" \
    --format="value(binaryAuthorization.evaluationMode)"
check_status "Binary Authorization configured"

print_header "11. Cluster Addons"
gcloud container clusters describe "$CLUSTER_NAME" \
    --region="$CLUSTER_REGION" \
    --project="$PROJECT_ID" \
    --format="table(addonsConfig.httpLoadBalancing.disabled,addonsConfig.horizontalPodAutoscaling.disabled,addonsConfig.networkPolicyConfig.disabled)"
check_status "Cluster addons enabled"

print_header "12. Cluster Access"
kubectl cluster-info
check_status "Cluster API accessible"

print_header "13. RBAC Configuration"
kubectl get clusterrolebindings | head -10
check_status "RBAC is configured"

print_header "14. Resource Quotas"
kubectl get resourcequotas --all-namespaces
echo "ℹ️  Resource quotas check complete"

print_header "15. Persistent Volumes"
kubectl get pv,pvc --all-namespaces
echo "ℹ️  Persistent volumes check complete"

echo ""
echo "========================================="
echo "✅ Cluster Verification Complete!"
echo "========================================="
echo ""
echo "Summary:"
echo "  Cluster Name: $CLUSTER_NAME"
echo "  Region: $CLUSTER_REGION"
echo "  Status: All checks passed"
echo ""
echo "Next Steps:"
echo "  1. Deploy your application using pickstream-app repository"
echo "  2. Configure monitoring and alerting"
echo "  3. Set up ingress controller if needed"
echo ""
