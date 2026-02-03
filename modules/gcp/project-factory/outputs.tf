# outputs.tf

output "project_id" {
  description = "The ID of the created GCP project."
  value       = module.project_factory.project_id
}

output "project_number" {
  description = "The number of the created GCP project."
  value       = module.project_factory.project_number
}

output "project_name" {
  description = "The name of the created GCP project."
  value       = module.project_factory.project_name
}

output "generic_service_account_email" {
  description = "The email address of the created general-purpose service account."
  value       = module.project_factory.service_account_email
}

output "generic_service_account_unique_id" {
  description = "The unique ID of the created general-purpose service account."
  value       = module.project_factory.service_account_unique_id
}

output "generic_service_account_name" {
  description = "The full name of the created general-purpose service account."
  value       = module.project_factory.service_account_name
}

output "enabled_apis" {
  description = "List of APIs enabled on the project."
  value       = module.project_factory.enabled_apis
}

# --- Tofu Backend Outputs ---
output "tofu_state_bucket_name" {
  description = "The name of the GCS bucket created for Tofu state."
  value       = google_storage_bucket.tofu_state_bucket.name
}

output "tofu_state_bucket_url" {
  description = "The gsutil URL of the GCS bucket for Tofu state."
  value       = google_storage_bucket.tofu_state_bucket.url
}

output "tofu_sa_email" {
  description = "The email address of the Tofu provisioner service account."
  value       = google_service_account.tofu_sa.email
}

output "tofu_sa_unique_id" {
  description = "The unique ID of the Tofu provisioner service account."
  value       = google_service_account.tofu_sa.unique_id
}

# --- WIF Outputs (Hub & Spoke Model) ---
# Note: WIF Pool and Provider are managed centrally in openjusticeok/infrastructure
# This module only creates IAM bindings to the global provider

output "wif_provider_name" {
  description = "The global WIF provider name passed to this module. Only set if enable_wif is true."
  value       = var.enable_wif ? var.wif_provider_name : null
}

output "github_actions_sa_email" {
  description = "The service account email for GitHub Actions to impersonate. Only set if enable_wif is true."
  value       = var.enable_wif ? google_service_account.tofu_sa.email : null
}

