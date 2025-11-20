output "repository_id" {
  description = "Artifact Registry repository ID"
  value       = google_artifact_registry_repository.pickstream.repository_id
}

output "repository_url" {
  description = "Full repository URL"
  value       = "${var.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.pickstream.repository_id}"
}

output "location" {
  description = "Repository location"
  value       = google_artifact_registry_repository.pickstream.location
}
