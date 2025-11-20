# Troubleshooting Guide

Common issues and solutions for PickStream GKE infrastructure.

## Table of Contents

- [Terraform Issues](#terraform-issues)
- [GKE Cluster Issues](#gke-cluster-issues)
- [Networking Issues](#networking-issues)
- [Node Pool Issues](#node-pool-issues)
- [kubectl Issues](#kubectl-issues)
- [Authentication Issues](#authentication-issues)
- [Cost Issues](#cost-issues)

---

## Terraform Issues

### Error: Backend initialization failed

**Symptoms:**
```
Error: Failed to get existing workspaces: storage: bucket doesn't exist
```

**Solution:**
```bash
# Verify bucket exists
gsutil ls gs://your-bucket-name

# Create bucket if missing
gsutil mb -p your-project-id -l us-central1 gs://your-bucket-name

# Re-initialize
terraform init -reconfigure
```

### Error: Error acquiring the state lock

**Symptoms:**
```
Error: Error acquiring the state lock
Lock Info:
  ID:        xxxxx-xxxx-xxxx-xxxx-xxxxxxxxx
```

**Solution:**
```bash
# Force unlock (use with caution - make sure no other applies are running)
terraform force-unlock xxxxx-xxxx-xxxx-xxxx-xxxxxxxxx

# Or delete the lock file from GCS
gsutil rm gs://your-bucket/path/to/state/default.tflock
```

### Error: Insufficient permissions

**Symptoms:**
```
Error: googleapi: Error 403: The caller does not have permission
```

**Solution:**
```bash
# Check current permissions
gcloud projects get-iam-policy your-project-id \
    --flatten="bindings[].members" \
    --filter="bindings.members:serviceAccount:your-sa@project.iam.gserviceaccount.com"

# Grant missing permissions
gcloud projects add-iam-policy-binding your-project-id \
    --member="serviceAccount:your-sa@project.iam.gserviceaccount.com" \
    --role="roles/container.admin"
```

### Error: Resource quota exceeded

**Symptoms:**
```
Error: Error creating Cluster: googleapi: Error 403: Quota 'CPUS' exceeded
```

**Solution:**
```bash
# Check current quotas
gcloud compute project-info describe --project=your-project-id

# Request quota increase at:
# https://console.cloud.google.com/iam-admin/quotas

# Or reduce node pool sizes in terraform.tfvars
```

---

## GKE Cluster Issues

### Cluster creation is stuck

**Symptoms:**
- Cluster status shows "PROVISIONING" for more than 15 minutes

**Solution:**
```bash
# Check cluster status
gcloud container clusters describe pickstream-cluster \
    --region=us-central1 \
    --format="value(status,statusMessage)"

# Check operations
gcloud container operations list \
    --region=us-central1

# If truly stuck, destroy and recreate
terraform destroy -target=google_container_cluster.primary
terraform apply
```

### Cluster is unhealthy

**Symptoms:**
```
Current master version: DEGRADED
```

**Solution:**
```bash
# Check cluster health
gcloud container clusters describe pickstream-cluster \
    --region=us-central1 \
    --format="table(status,currentMasterVersion,nodeIpv4CidrSize)"

# Trigger manual repair
gcloud container clusters upgrade pickstream-cluster \
    --region=us-central1 \
    --cluster-version=latest

# Check master logs
gcloud logging read "resource.type=k8s_cluster AND resource.labels.cluster_name=pickstream-cluster" \
    --limit=50 \
    --format=json
```

### Cannot access cluster

**Symptoms:**
```
Unable to connect to the server: dial tcp: lookup xxx on xxx: no such host
```

**Solution:**
```bash
# Re-fetch credentials
gcloud container clusters get-credentials pickstream-cluster \
    --region=us-central1 \
    --project=your-project-id

# Verify cluster endpoint
gcloud container clusters describe pickstream-cluster \
    --region=us-central1 \
    --format="value(endpoint)"

# Check firewall rules
gcloud compute firewall-rules list --filter="name~pickstream"

# Test connectivity
kubectl cluster-info dump
```

---

## Networking Issues

### Pods cannot reach internet

**Symptoms:**
- Pods show "ImagePullBackOff"
- Cannot resolve external DNS

**Solution:**
```bash
# Check Cloud NAT
gcloud compute routers nats list \
    --router=pickstream-router \
    --region=us-central1

# Verify NAT is working
kubectl run -it --rm test --image=busybox --restart=Never -- sh
# Inside pod:
wget -O- http://ifconfig.me

# Check NAT logs
gcloud logging read "resource.type=nat_gateway" --limit=10
```

### LoadBalancer service stuck in "Pending"

**Symptoms:**
```
TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)
LoadBalancer   10.4.0.5        <pending>     80:30000/TCP
```

**Solution:**
```bash
# Check service events
kubectl describe svc your-service-name

# Check if backend service is created
gcloud compute backend-services list

# Check firewall rules
gcloud compute firewall-rules list

# Verify node health checks
kubectl get nodes
kubectl describe node node-name | grep -A 10 Conditions
```

### Network policy blocking traffic

**Symptoms:**
- Pods cannot communicate with each other
- Services not accessible

**Solution:**
```bash
# List network policies
kubectl get networkpolicies --all-namespaces

# Describe specific policy
kubectl describe networkpolicy policy-name -n namespace

# Temporarily disable for testing
kubectl delete networkpolicy policy-name -n namespace

# Check pod labels match selectors
kubectl get pods --show-labels -n namespace
```

---

## Node Pool Issues

### Nodes not auto-scaling

**Symptoms:**
- Pods stuck in "Pending" state
- Nodes not being added despite resource requests

**Solution:**
```bash
# Check node pool autoscaling config
gcloud container node-pools describe app-pool \
    --cluster=pickstream-cluster \
    --region=us-central1 \
    --format="value(autoscaling)"

# Check cluster autoscaler logs
kubectl logs -n kube-system -l app=cluster-autoscaler

# Manually scale node pool
gcloud container clusters resize pickstream-cluster \
    --node-pool=app-pool \
    --num-nodes=3 \
    --region=us-central1
```

### Nodes in "NotReady" state

**Symptoms:**
```
NAME            STATUS     ROLES    AGE
gke-node-1      NotReady   <none>   5m
```

**Solution:**
```bash
# Check node conditions
kubectl describe node gke-node-1

# Check kubelet logs
gcloud compute ssh gke-node-1 --zone=us-central1-a
# On node:
sudo journalctl -u kubelet -n 100

# Restart node
kubectl drain gke-node-1 --ignore-daemonsets --delete-emptydir-data
kubectl delete node gke-node-1

# Node will be recreated automatically
```

### Node pool upgrade fails

**Symptoms:**
```
Error: Error waiting for updating NodePool: Timeout while waiting for operation
```

**Solution:**
```bash
# Check upgrade status
gcloud container operations list --region=us-central1

# Cancel stuck operation
gcloud container operations cancel operation-id --region=us-central1

# Manually upgrade one node at a time
kubectl drain node-name --ignore-daemonsets
kubectl delete node node-name

# Or rollback
terraform apply -var="kubernetes_version=1.27"
```

---

## kubectl Issues

### kubectl not connecting

**Symptoms:**
```
The connection to the server localhost:8080 was refused
```

**Solution:**
```bash
# Check kubeconfig
kubectl config view

# Get credentials again
gcloud container clusters get-credentials pickstream-cluster \
    --region=us-central1 \
    --project=your-project-id

# Verify context
kubectl config current-context

# Test connection
kubectl version
kubectl cluster-info
```

### Insufficient permissions in kubectl

**Symptoms:**
```
Error from server (Forbidden): pods is forbidden: User cannot list resource "pods"
```

**Solution:**
```bash
# Check current user
kubectl auth whoami

# Check user permissions
kubectl auth can-i list pods

# Grant cluster admin (for testing only)
kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole=cluster-admin \
    --user=$(gcloud config get-value account)

# Or create proper RBAC roles
kubectl create rolebinding my-binding \
    --clusterrole=view \
    --user=your-email@example.com \
    --namespace=default
```

---

## Authentication Issues

### Workload Identity not working

**Symptoms:**
- Pods cannot access GCP services
- Error: "Could not load the default credentials"

**Solution:**
```bash
# Verify Workload Identity is enabled
gcloud container clusters describe pickstream-cluster \
    --region=us-central1 \
    --format="value(workloadIdentityConfig.workloadPool)"

# Check service account annotation
kubectl describe serviceaccount my-ksa -n my-namespace

# Verify IAM binding
gcloud iam service-accounts get-iam-policy my-gsa@project.iam.gserviceaccount.com

# Create binding if missing
gcloud iam service-accounts add-iam-policy-binding my-gsa@project.iam.gserviceaccount.com \
    --role=roles/iam.workloadIdentityUser \
    --member="serviceAccount:project.svc.id.goog[namespace/ksa-name]"
```

### Service account key not working

**Symptoms:**
```
Error: google: could not find default credentials
```

**Solution:**
```bash
# Verify key file exists
ls -la ~/terraform-sa-key.json

# Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS=~/terraform-sa-key.json

# Verify credentials work
gcloud auth application-default print-access-token

# If key is invalid, create new one
gcloud iam service-accounts keys create ~/new-key.json \
    --iam-account=terraform-sa@project.iam.gserviceaccount.com
```

---

## Cost Issues

### Unexpected high costs

**Symptoms:**
- Cloud billing shows higher than expected charges

**Solution:**
```bash
# Check current resource usage
gcloud compute instances list
gcloud compute disks list
gcloud compute addresses list
gcloud container clusters list

# Check for zombie resources
gcloud compute instances list --filter="status=TERMINATED"
gcloud compute disks list --filter="users:''*"

# Enable cost optimization
# 1. Use preemptible nodes
# 2. Enable cluster autoscaling
# 3. Set resource requests/limits
# 4. Delete unused load balancers
# 5. Delete unused disks

# Set up budget alerts
gcloud billing budgets create \
    --billing-account=BILLING_ACCOUNT_ID \
    --display-name="GKE Budget" \
    --budget-amount=200USD
```

### Cost optimization tips

```bash
# 1. Use preemptible nodes (saves 80%)
# In terraform.tfvars:
use_preemptible_nodes = true

# 2. Right-size node pools
app_node_pool_machine_type = "e2-medium"  # Instead of e2-standard-2

# 3. Enable autoscaling
app_node_pool_min_count = 1  # Scale down when idle
app_node_pool_max_count = 5

# 4. Use regional persistent disks sparingly
# 5. Delete unused load balancers
gcloud compute forwarding-rules list
gcloud compute forwarding-rules delete unused-lb --region=us-central1

# 6. Monitor costs
gcloud billing accounts list
gcloud billing projects describe your-project-id
```

---

## General Debugging Commands

### Cluster information
```bash
# Cluster details
kubectl cluster-info
kubectl cluster-info dump

# Node information
kubectl get nodes -o wide
kubectl top nodes
kubectl describe nodes

# Component status
kubectl get componentstatuses
```

### Pod debugging
```bash
# Pod status
kubectl get pods --all-namespaces
kubectl describe pod pod-name -n namespace
kubectl logs pod-name -n namespace
kubectl logs pod-name -n namespace --previous

# Execute commands in pod
kubectl exec -it pod-name -n namespace -- sh

# Port forward for testing
kubectl port-forward pod-name 8080:8080 -n namespace
```

### Network debugging
```bash
# Test pod network
kubectl run -it --rm debug --image=busybox --restart=Never -- sh

# Inside pod:
nslookup kubernetes.default
wget -O- http://service-name.namespace.svc.cluster.local

# DNS debugging
kubectl run -it --rm dnsutils --image=gcr.io/kubernetes-e2e-test-images/dnsutils:1.3 --restart=Never -- sh
```

### Resource debugging
```bash
# Check resource usage
kubectl top pods --all-namespaces
kubectl top nodes

# Check resource limits
kubectl describe resourcequotas -n namespace
kubectl describe limitranges -n namespace
```

---

## Getting More Help

### Enable debug logging

```bash
# Terraform debug
export TF_LOG=DEBUG
terraform apply

# kubectl debug
kubectl get pods -v=9

# gcloud debug
gcloud container clusters describe pickstream-cluster --log-http
```

### Collect diagnostics

```bash
# Cluster diagnostics
kubectl cluster-info dump > cluster-dump.txt

# Node logs
for node in $(kubectl get nodes -o name); do
    kubectl describe $node > ${node}-describe.txt
done

# Pod logs
kubectl logs --all-containers=true -l app=your-app > app-logs.txt
```

### Support channels

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Terraform GCP Provider Issues](https://github.com/hashicorp/terraform-provider-google/issues)
- [Stack Overflow - GKE Tag](https://stackoverflow.com/questions/tagged/google-kubernetes-engine)
- [GCP Support](https://cloud.google.com/support)

---

## Still Stuck?

1. Check [SETUP.md](SETUP.md) for detailed setup instructions
2. Review [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
3. Open an issue in this repository
4. Contact the instructor

