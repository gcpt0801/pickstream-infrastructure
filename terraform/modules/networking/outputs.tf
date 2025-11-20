output "network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.vpc_network.name
}

output "network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.vpc_network.id
}

output "subnetwork_name" {
  description = "Name of the GKE subnetwork"
  value       = google_compute_subnetwork.gke_subnetwork.name
}

output "subnetwork_id" {
  description = "ID of the GKE subnetwork"
  value       = google_compute_subnetwork.gke_subnetwork.id
}

output "router_name" {
  description = "Name of the Cloud Router"
  value       = google_compute_router.router.name
}

output "nat_name" {
  description = "Name of the Cloud NAT"
  value       = google_compute_router_nat.nat.name
}
