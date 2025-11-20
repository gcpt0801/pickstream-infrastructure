resource "google_artifact_registry_repository" "pickstream" {
  location      = var.location
  repository_id = var.repository_id
  description   = var.description
  format        = "DOCKER"
  project       = var.project_id

  docker_config {
    immutable_tags = var.immutable_tags
  }

  labels = var.labels
}

# IAM binding for GKE nodes to pull images
resource "google_artifact_registry_repository_iam_member" "gke_reader" {
  project    = var.project_id
  location   = google_artifact_registry_repository.pickstream.location
  repository = google_artifact_registry_repository.pickstream.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.gke_node_service_account}"
}

# IAM binding for GitHub Actions to push images
resource "google_artifact_registry_repository_iam_member" "github_writer" {
  project    = var.project_id
  location   = google_artifact_registry_repository.pickstream.location
  repository = google_artifact_registry_repository.pickstream.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${var.github_service_account}"
}
