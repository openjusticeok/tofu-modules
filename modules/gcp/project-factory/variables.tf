# variables.tf

variable "project_name" {
  description = "The display name for the new GCP project. This will be used to create a unique project id unless specified."
  type        = string
}

variable "project_id" {
  description = "Optional. Specify a custom project ID to override the generated one. If not set, an ID will be generated from the project_name."
  type        = string
  default = null
}

variable "billing_account" {
  description = "The ID of the billing account to associate with the project (e.g., '012345-6789AB-CDEF01')."
  type        = string
}

variable "folder_id" {
  description = "The ID of the folder to create the project in (e.g., 'folders/123456789012'). Leave empty to create under the organization."
  type        = string
  default     = null
}

variable "org_id" {
  description = "The ID of the organization to create the project in (e.g., 'organizations/12345678901'). Required if folder_id is not set and project is part of an organization."
  type        = string
  default     = null
}

variable "labels" {
  description = "A map of labels to apply to the project."
  type        = map(string)
  default     = {}
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

variable "user_service_account_id" {
  description = "The desired ID for the new general-purpose service account (e.g., 'my-app-sa'). This will be the part before '@'."
  type        = string
}

variable "user_service_account_project_roles" {
  description = "A list of project-level IAM roles to grant to the general-purpose service account (e.g., ['roles/viewer', 'roles/storage.objectAdmin'])."
  type        = list(string)
  default     = ["roles/viewer"] # Opinionated default: start with viewer role
}

variable "disable_dependent_services" {
  description = "If true, services that are enabled and dependent on this service should also be disabled when this service is destroyed. Default is true."
  type        = bool
  default     = true
}

# --- Variables for Tofu Backend Setup ---
variable "enable_tofu_backend_setup" {
  description = "If true, creates a GCS bucket for Tofu state and a dedicated Tofu provisioner service account."
  type        = bool
  default     = false
}

variable "tofu_state_bucket_name_suffix" {
  description = "A suffix to append to the project ID to form the Tofu state bucket name. The final name will be '<project_id>-<suffix>-tfstate'. If empty, '-tfstate' will be used."
  type        = string
  default     = "tfstate"
}

variable "tofu_state_bucket_location" {
  description = "The location for the Tofu state GCS bucket (e.g., 'US-CENTRAL1')."
  type        = string
  default     = "US-CENTRAL1"
}

variable "tofu_state_bucket_storage_class" {
  description = "The storage class for the Tofu state GCS bucket."
  type        = string
  default     = "STANDARD"
}

variable "tofu_state_bucket_force_destroy" {
  description = "When deleting the Tofu state GCS bucket, this boolean option will delete all objects in the bucket. WARNING: Setting this to true will delete all Tofu state files irreversibly."
  type        = bool
  default     = false # Safety default
}

variable "tofu_provisioner_sa_id" {
  description = "The ID for the Tofu provisioner service account (e.g., 'tofu-provisioner'). Used if enable_tofu_backend_setup is true."
  type        = string
  default     = "tofu-provisioner"
}

variable "tofu_provisioner_sa_display_name" {
  description = "The display name for the Tofu provisioner service account."
  type        = string
  default     = "OpenTofu Provisioner SA"
}

variable "tofu_provisioner_sa_project_roles" {
  description = "A list of project-level IAM roles to grant to the Tofu provisioner service account."
  type        = list(string)
  default     = ["roles/owner"] # Opinionated default: owner for broad provisioning capabilities
}

# --- Variables for Workload Identity Federation (WIF) ---
variable "enable_wif" {
  description = "If true, creates Workload Identity Federation resources to allow GitHub Actions to impersonate the Tofu provisioner service account. Requires enable_tofu_backend_setup to be true."
  type        = bool
  default     = false
}

variable "github_repository" {
  description = "The GitHub repository (in 'owner/repo' format) that should be allowed to impersonate the Tofu provisioner service account via WIF. Required if enable_wif is true."
  type        = string
  default     = null
  validation {
    condition = var.enable_wif == false || (var.github_repository != null && can(regex("^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+$", var.github_repository)))
    error_message = "GitHub repository must be in 'owner/repo' format when enable_wif is true."
  }
}

variable "wif_pool_id" {
  description = "The ID for the Workload Identity Pool. Defaults to 'github-actions-pool'."
  type        = string
  default     = "github-actions-pool"
}

variable "wif_provider_id" {
  description = "The ID for the Workload Identity Provider within the pool. Defaults to 'github-provider'."
  type        = string
  default     = "github-provider"
}

variable "github_actions_conditions" {
  description = "Additional conditions for GitHub Actions access. Defaults to allowing access from main branch and pull requests."
  type        = list(string)
  default = [
    "assertion.ref == 'refs/heads/main'",
    "assertion.ref_type == 'branch'",
    "'pull_request' in assertion.event_name"
  ]
}

