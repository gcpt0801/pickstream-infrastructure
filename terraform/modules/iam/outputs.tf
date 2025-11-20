output "node_service_account_email" {
  description = "Email of the GKE nodes service account"
  value       = google_service_account.gke_nodes.email
}

output "workload_identity_service_account_email" {
  description = "Email of the Workload Identity service account"
  value       = google_service_account.workload_identity.email
}

output "artifact_registry_service_account_email" {
  description = "Email of the Artifact Registry service account"
  value       = google_service_account.artifact_registry.email
}

output "github_service_account_email" {
  description = "Email of the GitHub Actions service account"
  value       = google_service_account.github_actions.email
}

output "github_service_account_name" {
  description = "Full resource name of the GitHub Actions service account"
  value       = google_service_account.github_actions.name
}
