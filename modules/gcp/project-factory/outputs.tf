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
  description = "The name of the GCS bucket created for Tofu state. Only set if enable_tofu_backend_setup is true."
  value       = var.enable_tofu_backend_setup ? google_storage_bucket.tofu_state_bucket[0].name : null
}

output "tofu_state_bucket_url" {
  description = "The gsutil URL of the GCS bucket for Tofu state. Only set if enable_tofu_backend_setup is true."
  value       = var.enable_tofu_backend_setup ? google_storage_bucket.tofu_state_bucket[0].url : null
}

output "tofu_provisioner_sa_email" {
  description = "The email address of the Tofu provisioner service account. Only set if enable_tofu_backend_setup is true."
  value       = var.enable_tofu_backend_setup ? google_service_account.tofu_provisioner_sa[0].email : null
}

output "tofu_provisioner_sa_unique_id" {
  description = "The unique ID of the Tofu provisioner service account. Only set if enable_tofu_backend_setup is true."
  value       = var.enable_tofu_backend_setup ? google_service_account.tofu_provisioner_sa[0].unique_id : null
}

# --- WIF Outputs ---
output "wif_pool_name" {
  description = "The full name of the Workload Identity Pool. Only set if enable_wif is true."
  value       = var.enable_tofu_backend_setup && var.enable_wif ? google_iam_workload_identity_pool.github_pool[0].name : null
}

output "wif_provider_name" {
  description = "The full name of the Workload Identity Provider. Only set if enable_wif is true."
  value       = var.enable_tofu_backend_setup && var.enable_wif ? google_iam_workload_identity_pool_provider.github_provider[0].name : null
}

output "github_actions_sa_email" {
  description = "The service account email for GitHub Actions to impersonate. Only set if enable_wif is true."
  value       = var.enable_tofu_backend_setup && var.enable_wif ? google_service_account.tofu_provisioner_sa[0].email : null
}

output "wif_audience" {
  description = "The audience value to use in GitHub Actions for WIF authentication. Only set if enable_wif is true."
  value       = var.enable_tofu_backend_setup && var.enable_wif ? "//iam.googleapis.com/${google_iam_workload_identity_pool.github_pool[0].name}/providers/${var.wif_provider_id}" : null
}

