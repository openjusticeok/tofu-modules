output "folder" {
  description = "The full google_folder resource that was created."
  value       = google_folder.environment_folder
}

output "projects" {
  description = "A map of the full project-factory module outputs for each environment created."
  value       = module.project
}

output "folder_id" {
  description = "The ID of the GCP folder created for the environments."
  value       = google_folder.environment_folder.id
}

output "project_ids" {
  description = "A map of project IDs created, keyed by environment name."
  value = {
    for k, v in module.project : k => v.project_id
  }
}

output "tofu_sa_emails" {
  description = "A map of provisioner service account emails, keyed by environment name."
  value = {
    for k, v in module.project : k => v.tofu_sa_email
  }
}

output "tofu_state_buckets" {
  description = "A map of the GCS bucket names created for the OpenTofu backend for each environment, keyed by environment name."
  value = {
    for k, v in module.project : k => v.tofu_state_bucket_name
  }
}
