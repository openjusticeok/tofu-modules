# outputs.tf

output "project_id" {
  description = "The ID of the created GCP project."
  value       = google_project.new_project.project_id
}

output "project_number" {
  description = "The number of the created GCP project."
  value       = google_project.new_project.number
}

output "project_name" {
  description = "The name of the created GCP project."
  value       = google_project.new_project.name
}

output "generic_service_account_email" {
  description = "The email address of the created general-purpose service account."
  value       = google_service_account.generic_sa.email
}

output "generic_service_account_unique_id" {
  description = "The unique ID of the created general-purpose service account."
  value       = google_service_account.generic_sa.unique_id
}

output "generic_service_account_name" {
  description = "The full name of the created general-purpose service account."
  value       = google_service_account.generic_sa.name
}

output "enabled_apis" {
  description = "List of APIs enabled on the project."
  value       = [for s in google_project_service.activated_apis : s.service]
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

