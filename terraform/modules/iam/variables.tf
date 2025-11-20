variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for workload identity"
  type        = string
  default     = "pickstream"
}

variable "kubernetes_service_account" {
  description = "Kubernetes service account name"
  type        = string
  default     = "pickstream-app"
}
