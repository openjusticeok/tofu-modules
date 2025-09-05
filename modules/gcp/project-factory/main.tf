# Opinionated wrapper around the terraform-google-modules project factory
# This provides sensible defaults for OpenJustice OK while leveraging the upstream module
module "project_factory" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  random_project_id = true
  
  # Core project configuration
  name              = var.project_name
  billing_account   = var.billing_account
  folder_id         = var.folder_id
  org_id            = var.org_id
  labels            = var.labels

  # API configuration with opinionated defaults
  activate_apis                   = var.activate_apis
  disable_dependent_services      = var.disable_dependent_services
  disable_services_on_destroy     = true

  # Service account configuration - use the upstream module's SA creation
  create_project_sa               = true
  project_sa_name                 = var.user_service_account_id
  sa_role                         = var.user_service_account_project_role

  # Opinionated defaults for OpenJustice OK
  auto_create_network             = false  # We prefer explicit network creation
  default_service_account         = "delete"  # Remove default SA for better security
  deletion_policy                 = "DELETE"  # Allow project deletion
}

# --- Tofu Backend Setup Resources (Conditional) ---

# GCS bucket for Tofu state
resource "google_storage_bucket" "tofu_state_bucket" {
  count = var.enable_tofu_backend_setup ? 1 : 0

  name                        = "${module.project_factory.project_name}-${var.tofu_state_bucket_name_suffix}"
  project                     = module.project_factory.project_id
  location                    = var.tofu_state_bucket_location
  storage_class               = var.tofu_state_bucket_storage_class
  force_destroy               = var.tofu_state_bucket_force_destroy
  uniform_bucket_level_access = true // Recommended for new buckets

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      # Example: delete noncurrent versions older than 30 days
      # num_newer_versions = 3 # Keep at least 3 newer versions
      age = 30 # Days after which noncurrent versions are deleted
    }
  }

  lifecycle_rule {
    action {
      type = "AbortIncompleteMultipartUpload"
    }
    condition {
      age = 1 # Days after which incomplete uploads are aborted
    }
  }

  labels = merge(
    var.labels,
    { "purpose" = "tofu-state-backend" }
  )

  depends_on = [module.project_factory]
}

# Service Account for Tofu to use for provisioning
resource "google_service_account" "tofu_provisioner_sa" {
  count = var.enable_tofu_backend_setup ? 1 : 0

  project      = module.project_factory.project_id
  account_id   = var.tofu_provisioner_sa_id
  display_name = var.tofu_provisioner_sa_display_name
  description  = "Service account for OpenTofu to manage resources in project ${module.project_factory.project_id}"

  depends_on = [module.project_factory]
}

# Grant Tofu Provisioner SA roles on the project, making sure it is the ONLY owner. This removes ownership from the Tofu orchestrator that provisions our projects from the infrastructure repo.
resource "google_project_iam_binding" "tofu_provisioner_sa_project_roles" {
  for_each = var.enable_tofu_backend_setup ? toset(var.tofu_provisioner_sa_project_roles) : toset([])

  project = module.project_factory.project_id
  role = each.key

  members = [
    "serviceAccount:${google_service_account.tofu_provisioner_sa[0].email}" # Access via index due to count
  ]

  depends_on = [google_service_account.tofu_provisioner_sa]
}

# Grant Tofu Provisioner SA access to the Tofu state bucket
resource "google_storage_bucket_iam_member" "tofu_provisioner_sa_state_bucket_access" {
  count = var.enable_tofu_backend_setup ? 1 : 0

  bucket = google_storage_bucket.tofu_state_bucket[0].name # Access via index due to count
  role   = "roles/storage.objectAdmin"                     # Full control over objects in the bucket
  member = "serviceAccount:${google_service_account.tofu_provisioner_sa[0].email}" # Access via index

  depends_on = [
    google_storage_bucket.tofu_state_bucket,
    google_service_account.tofu_provisioner_sa
  ]
}

# Grant the initial user SA (if different from provisioner) read access to state bucket
resource "google_storage_bucket_iam_member" "user_sa_state_bucket_read_access" {
  count = var.enable_tofu_backend_setup ? 1 : 0

  bucket = google_storage_bucket.tofu_state_bucket[0].name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${module.project_factory.service_account_email}"

  depends_on = [
    google_storage_bucket.tofu_state_bucket,
    module.project_factory,
    google_service_account.tofu_provisioner_sa # Ensure provisioner SA is created first
  ]
}

# --- Workload Identity Federation (WIF) Resources ---

# Workload Identity Pool for GitHub Actions
resource "google_iam_workload_identity_pool" "github_pool" {
  count = var.enable_tofu_backend_setup && var.enable_wif ? 1 : 0

  project                   = module.project_factory.project_id
  workload_identity_pool_id = var.wif_pool_id
  display_name              = "GitHub Actions Pool"
  description               = "Workload Identity Pool for GitHub Actions to access ${module.project_factory.project_id}"

  depends_on = [module.project_factory]
}

# Workload Identity Provider for GitHub
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  count = var.enable_tofu_backend_setup && var.enable_wif ? 1 : 0

  project                            = module.project_factory.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool[0].workload_identity_pool_id
  workload_identity_pool_provider_id = var.wif_provider_id
  display_name                       = "GitHub Provider"
  description                        = "GitHub OIDC provider for ${var.github_repository}"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  # Condition to restrict access to the specific GitHub repository
  attribute_condition = "assertion.repository == '${var.github_repository}'"

  depends_on = [google_iam_workload_identity_pool.github_pool]
}

# IAM binding to allow GitHub Actions to impersonate the Tofu provisioner service account
resource "google_service_account_iam_binding" "github_wif_binding" {
  count = var.enable_tofu_backend_setup && var.enable_wif ? 1 : 0

  service_account_id = google_service_account.tofu_provisioner_sa[0].name
  role               = "roles/iam.workloadIdentityUser"
  members             = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool[0].name}/attribute.repository/${var.github_repository}"
  ]
  
  depends_on = [
    google_iam_workload_identity_pool_provider.github_provider,
    google_service_account.tofu_provisioner_sa
  ]
}
