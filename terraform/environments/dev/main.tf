terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# IAM Module
module "iam" {
  source = "../../modules/iam"

  project_id   = var.project_id
  cluster_name = var.cluster_name
  environment  = var.environment
}

# Networking Module
module "networking" {
  source = "../../modules/networking"

  project_id   = var.project_id
  region       = var.region
  network_name = "${var.cluster_name}-network"
  environment  = var.environment
}

# GKE Module
module "gke" {
  source = "../../modules/gke"

  project_id          = var.project_id
  region              = var.region
  cluster_name        = var.cluster_name
  environment         = var.environment
  network_name        = module.networking.network_name
  subnetwork_name     = module.networking.subnetwork_name
  node_service_account = module.iam.node_service_account_email

  # System node pool configuration
  system_node_count  = var.system_node_count
  system_min_nodes   = var.system_min_nodes
  system_max_nodes   = var.system_max_nodes
  system_machine_type = var.system_machine_type

  # Application node pool configuration
  app_node_count    = var.app_node_count
  app_min_nodes     = var.app_min_nodes
  app_max_nodes     = var.app_max_nodes
  app_machine_type  = var.app_machine_type

  depends_on = [
    module.networking,
    module.iam
  ]
}
