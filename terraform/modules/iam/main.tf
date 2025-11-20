# Service account for GKE nodes
resource "google_service_account" "gke_nodes" {
  account_id   = "${var.cluster_name}-nodes-sa"
  display_name = "GKE Nodes Service Account for ${var.cluster_name}"
  description  = "Service account used by GKE nodes in ${var.environment} environment"
}

# Grant required roles to node service account
resource "google_project_iam_member" "gke_nodes_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_metadata_writer" {
  project = var.project_id
  role    = "roles/stackdriver.resourceMetadata.writer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# Service account for Workload Identity (application pods)
resource "google_service_account" "workload_identity" {
  account_id   = "${var.cluster_name}-workload-sa"
  display_name = "Workload Identity Service Account for ${var.cluster_name}"
  description  = "Service account for Kubernetes workloads using Workload Identity"
}

# Note: Workload Identity bindings are commented out because they require the GKE cluster
# to exist first. These should be configured after cluster creation or as part of app deployment.

# Service account for Artifact Registry access
resource "google_service_account" "artifact_registry" {
  account_id   = "${var.cluster_name}-artifact-sa"
  display_name = "Artifact Registry Service Account"
  description  = "Service account for pulling images from Artifact Registry"
}

resource "google_project_iam_member" "artifact_registry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.artifact_registry.email}"
}

# Workload Identity bindings will be configured after cluster creation
# These require the cluster's Workload Identity pool to exist first
