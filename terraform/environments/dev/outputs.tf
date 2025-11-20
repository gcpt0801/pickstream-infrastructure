output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = module.gke.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for the GKE cluster"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "cluster_location" {
  description = "Location of the GKE cluster"
  value       = module.gke.cluster_location
}

output "cluster_region" {
  description = "Region/Zone of the GKE cluster (for backward compatibility)"
  value       = module.gke.cluster_location
}

output "network_name" {
  description = "Name of the VPC network"
  value       = module.networking.network_name
}

output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --zone=${module.gke.cluster_location} --project=${var.project_id}"
}

output "workload_identity_service_account" {
  description = "Workload Identity service account email"
  value       = module.iam.workload_identity_service_account_email
}

# Artifact Registry outputs
output "artifact_registry_url" {
  description = "Artifact Registry repository URL"
  value       = module.artifact_registry.repository_url
}

output "artifact_registry_location" {
  description = "Artifact Registry location"
  value       = module.artifact_registry.location
}

# Workload Identity outputs
output "workload_identity_provider" {
  description = "Workload Identity Provider for GitHub Actions"
  value       = module.workload_identity.workload_identity_provider
}

output "github_service_account_email" {
  description = "GitHub Actions service account email"
  value       = module.iam.github_service_account_email
}
