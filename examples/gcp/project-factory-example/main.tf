# Example usage of the opinionated project factory module (v0.7.0+)
# This demonstrates creating a single GCP project with sensible defaults
#
# IMPORTANT: For multi-environment setups (dev/stg/prod), use the environment-factory
# module instead. It handles cross-environment artifact promotion automatically without
# circular dependency issues.
#
# This example shows single-project use cases:
# 1. Basic project creation
# 2. Project that needs to read artifacts from external projects (cross_project_artifact_access)

module "project_factory" {
  source = "../../../modules/gcp/project-factory"

  # Required variables
  name            = "Example Project"
  billing_account = "012345-6789AB-CDEF01"

  # Optional: specify a custom project ID
  # project_id       = "example-project-12345"

  # Optional: place project in a folder (recommended for organization)
  folder_id = "folders/123456789012"

  # Labels for resource organization
  labels = {
    environment = "example"
    team        = "infrastructure"
    purpose     = "demo"
  }

  # Enable additional APIs beyond the opinionated defaults
  # Note: artifactregistry.googleapis.com is now included by default in v0.7.0+
  activate_apis = [
    "bigquery.googleapis.com",   # BigQuery for analytics
    "cloudbuild.googleapis.com", # Cloud Build for CI/CD
  ]

  # Optional: Enable WIF for GitHub Actions integration (Hub & Spoke model)
  # Requires a global WIF pool from openjusticeok/infrastructure
  enable_wif        = true
  wif_pool_name     = "projects/12345/locations/global/workloadIdentityPools/github-pool"
  github_repository = "openjusticeok/example-project" # Replace with your GitHub repo

  # Optional: Cross-Project Artifact Access (v0.7.0+)
  # 
  # Use case: This SINGLE project needs to read container images or GCE disk images 
  # from EXTERNAL projects (e.g., your standalone prod project reading from external dev).
  #
  # ⚠️ WARNING: If you're creating multiple environments together (dev/stg/prod), 
  # use environment-factory with enable_cross_env_artifacts instead! The environment-factory
  # approach creates standalone IAM resources that avoid circular dependency issues.
  #
  # This example grants THIS project's provisioner SA read access to an external project:
  cross_project_artifact_access = [
    {
      project_id  = "external-project-dev-ab12"         # External project to read from
      location    = "us-central1"                       # Artifact Registry location
      repository  = "repo"                              # Artifact Registry repository name
      bucket_name = "external-project-dev-nixos-images" # GCS bucket for GCE images
    }
  ]
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

output "project_name" {
  description = "The created project name"
  value       = module.project_factory.project_name
}

output "generic_service_account_email" {
  description = "The generic service account email (if enabled)"
  value       = module.project_factory.generic_service_account_email
}

output "tofu_state_bucket_name" {
  description = "The GCS bucket for OpenTofu state management"
  value       = module.project_factory.tofu_state_bucket_name
}

output "tofu_sa_email" {
  description = "The Tofu provisioner service account email (for CI/CD authentication)"
  value       = module.project_factory.tofu_sa_email
}

output "wif_pool_name" {
  description = "The WIF pool name for GitHub Actions (if enabled)"
  value       = module.project_factory.wif_pool_name
}

output "github_actions_sa_email" {
  description = "The service account email for GitHub Actions to impersonate (if WIF enabled)"
  value       = module.project_factory.github_actions_sa_email
}

output "enabled_apis" {
  description = "List of enabled APIs"
  value       = module.project_factory.enabled_apis
}
