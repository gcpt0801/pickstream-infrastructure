variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "pool_id" {
  description = "Workload Identity Pool ID"
  type        = string
  default     = "github-pool"
}

variable "pool_display_name" {
  description = "Display name for the pool"
  type        = string
  default     = "GitHub Pool"
}

variable "pool_description" {
  description = "Description for the pool"
  type        = string
  default     = "Workload Identity Pool for GitHub Actions"
}

variable "provider_id" {
  description = "Workload Identity Provider ID"
  type        = string
  default     = "github-provider"
}

variable "provider_display_name" {
  description = "Display name for the provider"
  type        = string
  default     = "GitHub Provider"
}

variable "provider_description" {
  description = "Description for the provider"
  type        = string
  default     = "OIDC provider for GitHub Actions"
}

variable "attribute_condition" {
  description = "Attribute condition to restrict which GitHub repos can authenticate"
  type        = string
  default     = ""
}

variable "service_account_name" {
  description = "Full service account resource name (projects/{project}/serviceAccounts/{email})"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
}
