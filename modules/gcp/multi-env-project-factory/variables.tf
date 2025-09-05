variable "folder_display_name" {
  type        = string
  description = "The display name for the new folder that will contain the environment projects."
}

variable "parent_id" {
  type        = string
  description = "The ID of the parent resource (organization or folder) to create the new folder in. E.g., 'organizations/12345' or 'folders/67890'."
}

variable "project_name_prefix" {
  type        = string
  description = "A prefix for all created project names and IDs. e.g., 'my-app' will create 'my-app-dev', 'my-app-staging', etc."
}

variable "billing_account" {
  type        = string
  description = "The GCP billing account ID to link to the created projects."
}

variable "github_repo" {
  type        = string
  description = "The GitHub repository in 'owner/repo' format that will be granted access."
}

variable "environments" {
  type = map(object({
    branch_name = string
  }))
  description = "A map of environments to create, with their corresponding GitHub branch for `apply` operations."
  default = {
    "dev"     = { branch_name = "dev" }
    "stg" = { branch_name = "staging" }
    "prod"    = { branch_name = "main" }
  }
}

variable "activate_apis" {
  description = "A list of APIs to enable on the project."
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "storage.googleapis.com", // Needed for GCS buckets
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",       // Essential for managing services
    "iamcredentials.googleapis.com",     // For SA impersonation capabilities
    "logging.googleapis.com",            // Cloud Logging API
    "monitoring.googleapis.com",         // Cloud Monitoring API
  ]
}

variable "user_service_account_project_role" {
  description = "A project-level IAM role to grant to the general-purpose service account (e.g., 'roles/viewer', 'roles/editor')."
  type        = string
  default     = "roles/viewer" # Opinionated default: start with viewer role
}

variable "labels" {
  description = "A map of labels to apply to the project."
  type        = map(string)
  default     = {}
}
