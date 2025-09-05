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
    "staging" = { branch_name = "staging" }
    "prod"    = { branch_name = "main" }
  }
}

variable "plan_branch_pattern" {
  type        = string
  description = "The Git branch pattern (e.g., `refs/pull/*`) that is allowed to impersonate the **planner** service account (for `terraform plan`) across all environments."
  default     = "refs/pull/*"
}

variable "tofu_state_bucket_location" {
  type        = string
  description = "The location for the Tofu state GCS bucket for all projects (e.g., `US-CENTRAL1`)."
  default     = "US-CENTRAL1"
}
