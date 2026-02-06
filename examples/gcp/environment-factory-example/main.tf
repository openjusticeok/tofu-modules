# Example usage of the environment factory module (v0.7.0+)
# This demonstrates the RECOMMENDED approach for creating a multi-environment setup
# with automatic cross-environment artifact promotion
#
# NOTE: For multi-environment setups like dev/stg/prod, use environment-factory with
# enable_cross_env_artifacts = true instead of project-factory with cross_project_artifact_access.
# The environment-factory approach creates standalone IAM resources that avoid circular
# dependency issues.

module "environment_factory" {
  source = "../../../modules/gcp/environment-factory"

  # Organization and billing
  parent              = "organizations/YOUR_ORGANIZATION_ID" # Replace with your org ID
  folder_display_name = "My Application Environments"
  name                = "my-app"                  # Creates: my-app-dev, my-app-stg, my-app-prod
  billing_account     = "YOUR_BILLING_ACCOUNT_ID" # Replace with your billing account

  # GitHub repository for Workload Identity Federation
  github_repository = "openjusticeok/my-app"

  # Hub & Spoke: Pass the global WIF pool from openjusticeok/infrastructure
  # Get this value from openjusticeok/infrastructure outputs
  wif_pool_name = "projects/12345/locations/global/workloadIdentityPools/github-pool"

  # Environments to create (order matters for promotion chain!)
  # Index 0: dev, Index 1: stg, Index 2: prod
  # This creates an automatic waterfall: prod can read from stg and dev
  environments = ["dev", "stg", "prod"]

  # Enable cross-environment artifact promotion (v0.7.0+)
  # This creates STANDALONE IAM resources (not module inputs) that:
  # 1. Grant prod's provisioner SA read access to stg's artifact registry and GCS bucket
  # 2. Grant prod's provisioner SA read access to dev's artifact registry and GCS bucket
  # 3. Grant stg's provisioner SA read access to dev's artifact registry and GCS bucket
  # 
  # Why standalone resources? This avoids circular dependencies that would occur
  # if we passed cross-project references as inputs to the project-factory module.
  enable_cross_env_artifacts = true

  # Region for artifact registries (must match where your CI/CD builds artifacts)
  region = "us-central1"

  # Optional: Custom labels applied to all projects
  labels = {
    team = "platform-engineering"
    app  = "my-app"
  }

  # Optional: Additional APIs beyond the defaults
  # Note: artifactregistry.googleapis.com is now included by default in v0.7.0+
  activate_apis = [
    "compute.googleapis.com",
    "storage.googleapis.com",
    "iam.googleapis.com",
    "run.googleapis.com",        # Cloud Run
    "cloudbuild.googleapis.com", # Cloud Build
  ]

  # Optional: Custom service account role (default: roles/owner)
  tofu_sa_role = "roles/editor"
}

# Example outputs - useful for configuring CI/CD pipelines
output "folder" {
  description = "The created folder resource"
  value       = module.environment_factory.folder
}

output "project_ids" {
  description = "Map of environment names to project IDs (e.g., module.environment_factory.project_ids['dev'])"
  value       = module.environment_factory.project_ids
}

output "dev_project_id" {
  description = "The dev project ID - use this in CI/CD for dev deployments"
  value       = module.environment_factory.project_ids["dev"]
}

output "stg_project_id" {
  description = "The staging project ID - use this in CI/CD for staging deployments"
  value       = module.environment_factory.project_ids["stg"]
}

output "prod_project_id" {
  description = "The production project ID - use this in CI/CD for production deployments"
  value       = module.environment_factory.project_ids["prod"]
}

output "tofu_sa_emails" {
  description = "Map of environment names to Tofu provisioner service account emails (for CI/CD auth)"
  value       = module.environment_factory.tofu_sa_emails
}

output "tofu_state_buckets" {
  description = "Map of environment names to Tofu state bucket names"
  value       = module.environment_factory.tofu_state_buckets
}

# Example: Access all outputs from a specific environment's project
output "dev_project_details" {
  description = "All outputs from the dev project (service accounts, buckets, etc.)"
  value       = module.environment_factory.projects["dev"]
}
