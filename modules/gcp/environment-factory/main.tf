resource "google_folder" "environment_folder" {
  display_name        = var.folder_display_name
  parent              = var.parent_id
  deletion_protection = false
}

module "project" {
  source   = "../project-factory"
  for_each = toset(var.environments)

  project_name                      = "${var.project_name}-${each.key}"
  billing_account                   = var.billing_account
  folder_id                         = google_folder.environment_folder.id
  github_repository                 = var.github_repository
  user_service_account_id           = "${var.project_name}-${each.key}-sa"
  user_service_account_project_role = var.user_service_account_project_role

  # Enable Tofu backend setup and WIF for each project
  enable_tofu_backend_setup = true
  enable_wif                = true

  # Active APIs
  activate_apis = var.activate_apis

  # Labels
  labels = var.labels
}