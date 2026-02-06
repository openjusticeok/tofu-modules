resource "google_folder" "environment_folder" {
  display_name        = var.folder_display_name
  parent              = var.parent
  deletion_protection = false
}

locals {
  # Create a map of environment -> index for ordering (dev=0, stg=1, prod=2)
  env_indices = { for idx, env in var.environments : env => idx }
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

  depends_on = [google_folder.environment_folder]
}

# Cross-project Artifact Registry access for promotion workflows (v0.7.0+)
# These are standalone resources that depend on all projects being created first
# This avoids the circular dependency that would occur if passed as module inputs
resource "google_artifact_registry_repository_iam_member" "cross_project_reader" {
  # Only create if cross-env artifacts are enabled
  for_each = var.enable_cross_env_artifacts ? {
    # Create a unique key for each source-target pair
    for pair in setproduct(
      # Target environments (higher index)
      [for env in var.environments : env if local.env_indices[env] > 0],
      # Source environments (lower index than their corresponding target)
      var.environments
      ) : "${pair[0]}-from-${pair[1]}" => {
      target_env = pair[0]
      source_env = pair[1]
    } if local.env_indices[pair[1]] < local.env_indices[pair[0]]
  } : {}

  # Reference the source project's Artifact Registry
  project    = module.project[each.value.source_env].project_id
  location   = var.region
  repository = "repo"

  role = "roles/artifactregistry.reader"

  # Grant the target project's provisioner SA read access
  member = "serviceAccount:${module.project[each.value.target_env].tofu_sa_email}"

  depends_on = [module.project]
}

# Cross-project GCS bucket access for GCE images (v0.7.0+)
resource "google_storage_bucket_iam_member" "cross_project_bucket_reader" {
  # Same logic as above for pairing
  for_each = var.enable_cross_env_artifacts ? {
    for pair in setproduct(
      [for env in var.environments : env if local.env_indices[env] > 0],
      var.environments
      ) : "${pair[0]}-from-${pair[1]}" => {
      target_env = pair[0]
      source_env = pair[1]
    } if local.env_indices[pair[1]] < local.env_indices[pair[0]]
  } : {}

  # Reference the source project's GCS bucket
  bucket = "${var.name}-${each.value.source_env}-nixos-images"

  role = "roles/storage.objectViewer"

  # Grant the target project's provisioner SA read access
  member = "serviceAccount:${module.project[each.value.target_env].tofu_sa_email}"

  depends_on = [module.project]
}
