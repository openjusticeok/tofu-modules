resource "google_folder" "environment_folder" {
  display_name = var.folder_display_name
  parent       = var.parent_id
}

module "project" {
  source   = "../project-factory"
  for_each = var.environments

  project_name            = "${var.project_name_prefix}-${each.key}"
  project_id              = "${var.project_name_prefix}-${each.key}"
  billing_account         = var.billing_account
  folder_id               = google_folder.environment_folder.id
  github_repository       = var.github_repo

  # Enable Tofu backend setup and WIF for each project
  enable_tofu_backend_setup = true
  enable_wif                = true

  # Branch patterns for WIF
  apply_branch_pattern = each.value.branch_name
  plan_branch_pattern  = var.plan_branch_pattern

  # Tofu backend configuration
  tofu_state_bucket_location = var.tofu_state_bucket_location
  tofu_state_bucket_name_suffix = "${each.key}-tfstate"

  # Service account IDs (derived from environment name)
  user_service_account_id    = "app-${each.key}-sa"
  tofu_provisioner_sa_id     = "tofu-provisioner-${each.key}"

  # Pass through other variables if needed, or rely on project-factory defaults
  # labels = var.labels # Example if you want to pass labels
}
