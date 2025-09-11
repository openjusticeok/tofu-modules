output "folder_id" {
  description = "The ID of the GCP folder created for the environments."
  value       = google_folder.environment_folder.id
}

output "project_ids" {
  description = "A map of project IDs created, keyed by environment name."
  value       = {
    for k, v in module.project : k => v.project_id
  }
}

output "provisioner_sa_emails" {
  description = "A map of provisioner service account emails, keyed by environment name."
  value       = {
    for k, v in module.project : k => v.tofu_provisioner_sa_email
  }
}