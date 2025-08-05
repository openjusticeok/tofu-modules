# variables.tf

variable "project_id" {
  description = "The desired ID for the new GCP project. Must be unique globally."
  type        = string
  validation {
    condition     = length(var.project_id) >= 6 && length(var.project_id) <= 30 && can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be 6 to 30 characters, start with a lowercase letter, and contain only lowercase letters, numbers, or hyphens."
  }
}

variable "project_name" {
  description = "The display name for the new GCP project."
  type        = string
  default     = null # If null, will default to project_id in the resource
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

variable "service_account_id" {
  description = "The desired ID for the new general-purpose service account (e.g., 'my-app-sa'). This will be the part before '@'."
  type        = string
}

variable "service_account_display_name" {
  description = "The display name for the general-purpose service account."
  type        = string
  default     = null # If null, will default to a generated name or service_account_id
}

variable "service_account_description" {
  description = "A description for the general-purpose service account."
  type        = string
  default     = "General purpose service account managed by OpenTofu."
}

variable "service_account_project_roles" {
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

