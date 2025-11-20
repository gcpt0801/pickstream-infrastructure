output "pool_id" {
  description = "Workload Identity Pool ID"
  value       = google_iam_workload_identity_pool.github.workload_identity_pool_id
}

output "pool_name" {
  description = "Workload Identity Pool full resource name"
  value       = google_iam_workload_identity_pool.github.name
}

output "provider_id" {
  description = "Workload Identity Provider ID"
  value       = google_iam_workload_identity_pool_provider.github.workload_identity_pool_provider_id
}

output "provider_name" {
  description = "Workload Identity Provider full resource name"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "workload_identity_provider" {
  description = "Full workload identity provider for GitHub Actions"
  value       = "projects/${var.project_id}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github.workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.github.workload_identity_pool_provider_id}"
}
