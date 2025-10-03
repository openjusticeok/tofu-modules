resource "google_folder" "environment_folder" {
  display_name        = var.folder_display_name
  parent              = var.parent
  deletion_protection = false
}

module "project" {
  source   = "../project-factory"
  for_each = toset(var.environments)

  name                              = "${var.name}-${each.key}"
  billing_account                   = var.billing_account
  folder_id                         = google_folder.environment_folder.id
  github_repository                 = var.github_repository
  tofu_sa_name                      = var.tofu_sa_name
  tofu_sa_role                      = var.tofu_sa_role

  # Enable Tofu backend setup and WIF for each project
  enable_wif                = true

  # Active APIs
  activate_apis = var.activate_apis

  # Labels
  labels = var.labels
}