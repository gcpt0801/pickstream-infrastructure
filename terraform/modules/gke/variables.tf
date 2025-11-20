variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region for the GKE cluster"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnetwork_name" {
  description = "Name of the subnetwork"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "release_channel" {
  description = "GKE release channel (RAPID, REGULAR, STABLE)"
  type        = string
  default     = "REGULAR"
}

variable "node_service_account" {
  description = "Service account for GKE nodes"
  type        = string
}

# System node pool variables
variable "system_node_count" {
  description = "Initial number of nodes in system pool"
  type        = number
  default     = 2
}

variable "system_min_nodes" {
  description = "Minimum number of nodes in system pool"
  type        = number
  default     = 1
}

variable "system_max_nodes" {
  description = "Maximum number of nodes in system pool"
  type        = number
  default     = 5
}

variable "system_machine_type" {
  description = "Machine type for system node pool"
  type        = string
  default     = "e2-medium"
}

# Application node pool variables
variable "app_node_count" {
  description = "Initial number of nodes in application pool"
  type        = number
  default     = 3
}

variable "app_min_nodes" {
  description = "Minimum number of nodes in application pool"
  type        = number
  default     = 2
}

variable "app_max_nodes" {
  description = "Maximum number of nodes in application pool"
  type        = number
  default     = 10
}

variable "app_machine_type" {
  description = "Machine type for application node pool"
  type        = string
  default     = "e2-standard-2"
}
