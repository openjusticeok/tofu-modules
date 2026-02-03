resource "google_folder" "environment_folder" {
  display_name        = var.folder_display_name
  parent              = var.parent
  deletion_protection = false
}

module "project" {
  source   = "../project-factory"
  for_each = toset(var.environments)

  name              = "${var.name}-${each.key}"
  billing_account   = var.billing_account
  folder_id         = google_folder.environment_folder.id
  github_repository = var.github_repository
  tofu_sa_name      = var.tofu_sa_name
  tofu_sa_role      = var.tofu_sa_role

  # Hub & Spoke: Use global WIF pool instead of creating our own
  enable_wif    = true
  wif_pool_name = var.wif_pool_name

  # Active APIs
  activate_apis = var.activate_apis

  # Labels
  labels = var.labels
}