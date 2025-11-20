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
