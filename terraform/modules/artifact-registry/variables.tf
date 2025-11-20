variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "location" {
  description = "Artifact Registry location"
  type        = string
  default     = "us-central1"
}

variable "repository_id" {
  description = "Artifact Registry repository ID"
  type        = string
  default     = "pickstream"
}

variable "description" {
  description = "Repository description"
  type        = string
  default     = "Docker repository for Pickstream microservices"
}

variable "immutable_tags" {
  description = "Enable immutable tags"
  type        = bool
  default     = false
}

variable "labels" {
  description = "Labels to apply to the repository"
  type        = map(string)
  default     = {}
}

variable "gke_node_service_account" {
  description = "Service account email for GKE nodes"
  type        = string
}

variable "github_service_account" {
  description = "Service account email for GitHub Actions"
  type        = string
}
