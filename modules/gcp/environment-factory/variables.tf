variable "project_name" {
  description = "A name for all created project names and IDs. e.g., 'my-app' will create 'my-app-dev', 'my-app-staging', etc."
  type        = string
}

variable "folder_display_name" {
  description = "The display name for the new folder that will contain the environment projects."
  type        = string
}

variable "billing_account" {
  description = "The GCP billing account ID to link to the created projects."
  type        = string
}

variable "parent_id" {
  description = "The ID of the parent resource (organization or folder) to create the new folder in. E.g., 'organizations/12345' or 'folders/67890'."
  type        = string
}

variable "github_repository" {
  description = "The GitHub repository in 'owner/repo' format that will be granted access."
  type        = string
}

variable "environments" {
  description = "A list of environments to create."
  type        = list(string)
  default = [
    "dev",
    "stg",
    "prod"
  ]
}

variable "labels" {
  description = "A map of labels to apply to the project."
  type        = map(string)
  default     = {}
}

variable "activate_apis" {
  description = "A list of APIs to enable on the environments."
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "storage.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com"
  ]
}

variable "user_service_account_project_role" {
  description = "A project-level IAM role to grant to the general-purpose service account (e.g., 'roles/viewer', 'roles/editor')."
  type        = string
  default     = "roles/viewer"
}
