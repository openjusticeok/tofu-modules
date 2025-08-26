# Example usage of the opinionated project factory module
# This demonstrates how to create a GCP project with sensible defaults

module "project_factory" {
  source = "../../../modules/gcp/project-factory"

  # Required variables
  project_name     = "Example Project"
  billing_account  = "012345-6789AB-CDEF01"
  
  # Optional: specify a custom project ID
  # project_id       = "example-project-12345"

  # Optional: place project in a folder (recommended for organization)
  folder_id        = "folders/123456789012"

  # Service account configuration
  user_service_account_id = "example-sa"
  user_service_account_project_roles = [
    "roles/viewer",
    "roles/storage.objectViewer"
  ]

  # Labels for resource organization
  labels = {
    environment = "example"
    team        = "infrastructure"
    purpose     = "demo"
  }

  # Enable additional APIs beyond the opinionated defaults
  activate_apis = [
    "compute.googleapis.com",
    "storage.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "bigquery.googleapis.com",        # Additional API for this project
    "cloudbuild.googleapis.com",      # Additional API for this project
  ]

  # Optional: Enable OpenTofu backend setup
  enable_tofu_backend_setup = true
  tofu_state_bucket_location = "US-CENTRAL1"
  tofu_provisioner_sa_project_roles = [
    "roles/owner"
  ]

  # Optional: Enable WIF for GitHub Actions integration
  enable_wif        = true
  github_repository = "openjusticeok/example-project"  # Replace with your GitHub repo
  wif_pool_id       = "github-actions-pool"
  wif_provider_id   = "github-provider"
}

# Example outputs to show what's available
output "project_id" {
  description = "The created project ID"
  value       = module.project_factory.project_id
}

output "project_number" {
  description = "The created project number"
  value       = module.project_factory.project_number
}

output "service_account_email" {
  description = "The created service account email"
  value       = module.project_factory.generic_service_account_email
}

output "tofu_state_bucket" {
  description = "The GCS bucket for OpenTofu state (if enabled)"
  value       = module.project_factory.tofu_state_bucket_name
}

output "tofu_provisioner_sa_email" {
  description = "The Tofu provisioner service account email (if enabled)"
  value       = module.project_factory.tofu_provisioner_sa_email
}

output "wif_audience" {
  description = "The WIF audience for GitHub Actions (if enabled)"
  value       = module.project_factory.wif_audience
}

output "github_actions_sa_email" {
  description = "The service account email for GitHub Actions to impersonate (if WIF enabled)"
  value       = module.project_factory.github_actions_sa_email
}

output "enabled_apis" {
  description = "List of enabled APIs"
  value       = module.project_factory.enabled_apis
}
