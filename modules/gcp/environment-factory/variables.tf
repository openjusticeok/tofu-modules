variable "name" {
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

variable "parent" {
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

variable "tofu_sa_name" {
  description = "OpenTofu Provisioner service account name for the project."
  type        = string
  default     = "tofu-provisioner"
}

variable "tofu_sa_role" {
  description = "A role to give the OpenTofu Provisioner Service Account for the project (defaults to owner)"
  type        = string
  default     = "roles/owner"
}

variable "wif_pool_name" {
  description = "The full resource name of the global Workload Identity Pool from openjusticeok/infrastructure (e.g., 'projects/12345/locations/global/workloadIdentityPools/github-pool'). Passed to all environment projects."
  type        = string
}

variable "enable_cross_env_artifacts" {
  description = "Enable cross-environment artifact promotion. When true, grants each environment read access to all lower environments' artifact registries (e.g., prod can read from staging and dev)"
  type        = bool
  default     = false
}

variable "region" {
  description = "The GCP region for artifact registries (used for cross-project access configuration)"
  type        = string
  default     = "us-central1"
}
