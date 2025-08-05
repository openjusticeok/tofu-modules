# Resource to create the GCP Project
resource "google_project" "new_project" {
  project_id      = var.project_id
  name            = var.project_name == null ? var.project_id : var.project_name
  billing_account = var.billing_account
  folder_id       = var.folder_id
  org_id          = var.org_id # Only specify if folder_id is null and project is directly under an org
  labels          = var.labels

  # lifecycle {
  #   prevent_destroy = true # Optional: prevent accidental deletion of the project
  # }
}

# Resource to enable specified APIs on the new project
# Waits for the project to be created before attempting to enable APIs
resource "google_project_service" "activated_apis" {
  for_each = toset(var.activate_apis)

  project                    = google_project.new_project.project_id
  service                    = each.key
  disable_dependent_services = var.disable_dependent_services
  disable_on_destroy         = var.disable_services_on_destroy

  # Explicit dependency to ensure project creation is complete
  # and billing is properly associated before enabling APIs.
  depends_on = [google_project.new_project]
}

# Resource to create a new general-purpose Service Account within the project
# Waits for APIs (especially IAM API) to be enabled
resource "google_service_account" "generic_sa" {
  project      = google_project.new_project.project_id
  account_id   = var.service_account_id
  display_name = var.service_account_display_name == null ? "Service Account ${var.service_account_id}" : var.service_account_display_name
  description  = var.service_account_description

  # Explicit dependency on API activation, particularly 'iam.googleapis.com'
  depends_on = [google_project_service.activated_apis["iam.googleapis.com"]] # Be specific if possible
}

# Resource to grant IAM roles to the general-purpose Service Account on the project level
# Waits for the service account to be created
resource "google_project_iam_member" "generic_sa_project_roles" {
  for_each = toset(var.service_account_project_roles)

  project = google_project.new_project.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.generic_sa.email}"

  depends_on = [google_service_account.generic_sa]
}

# --- Tofu Backend Setup Resources (Conditional) ---

# GCS bucket for Tofu state
resource "google_storage_bucket" "tofu_state_bucket" {
  count = var.enable_tofu_backend_setup ? 1 : 0

  name                        = "${google_project.new_project.project_id}-${var.tofu_state_bucket_name_suffix}"
  project                     = google_project.new_project.project_id
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

  depends_on = [
    google_project_service.activated_apis["storage.googleapis.com"], // Ensure Storage API is active
    google_project.new_project
  ]
}

# Service Account for Tofu to use for provisioning
resource "google_service_account" "tofu_provisioner_sa" {
  count = var.enable_tofu_backend_setup ? 1 : 0

  project      = google_project.new_project.project_id
  account_id   = var.tofu_provisioner_sa_id
  display_name = var.tofu_provisioner_sa_display_name
  description  = "Service account for OpenTofu to manage resources in project ${google_project.new_project.project_id}"

  depends_on = [google_project_service.activated_apis["iam.googleapis.com"]]
}

# Grant Tofu Provisioner SA roles on the project, making sure it is the ONLY owner. This removes ownership from the Tofu orchestrator that provisions our projects from the infrastructure repo.
resource "google_project_iam_member" "tofu_provisioner_sa_project_roles" {
  for_each = var.enable_tofu_backend_setup ? toset(var.tofu_provisioner_sa_project_roles) : toset([])

  project = google_project.new_project.project_id
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

# Optional: Grant the initial generic SA (if different from provisioner) read access to state bucket
# This might be useful if an analyst uses the generic_sa for read-only Tofu plans/show
# resource "google_storage_bucket_iam_member" "generic_sa_state_bucket_read_access" {
#   count = var.enable_tofu_backend_setup && google_service_account.generic_sa.email != google_service_account.tofu_provisioner_sa[0].email ? 1 : 0

#   bucket = google_storage_bucket.tofu_state_bucket[0].name
#   role   = "roles/storage.objectViewer"
#   member = "serviceAccount:${google_service_account.generic_sa.email}"

#   depends_on = [
#     google_storage_bucket.tofu_state_bucket,
#     google_service_account.generic_sa,
#     google_service_account.tofu_provisioner_sa # Ensure provisioner SA is created first
#   ]
# }

