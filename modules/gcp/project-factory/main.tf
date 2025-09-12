# Opinionated wrapper around the terraform-google-modules project factory
# This provides sensible defaults for OpenJustice OK while leveraging the upstream module
module "project_factory" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  random_project_id        = var.random_project_id
  random_project_id_length = var.random_project_id_length

  # Core project configuration
  org_id                         = var.org_id
  domain                         = var.domain
  name                           = var.name
  project_id                     = var.project_id
  svpc_host_project_id           = var.svpc_host_project_id
  enable_shared_vpc_host_project = var.enable_shared_vpc_host_project
  billing_account                = var.billing_account
  folder_id                      = var.folder_id
  group_name                     = var.group_name
  group_role                     = var.group_role

  # Service account configuration - use the upstream module's SA creation
  create_project_sa      = var.create_project_sa
  project_sa_name        = var.project_sa_name
  project_sa_description = var.project_sa_description
  sa_role                = var.sa_role

  # API configuration with opinionated defaults
  activate_apis           = var.activate_apis
  activate_api_identities = var.activate_api_identities

  # Usage Bucket
  usage_bucket_name   = var.usage_bucket_name
  usage_bucket_prefix = var.usage_bucket_prefix

  # VPC Subnets
  shared_vpc_subnets = var.shared_vpc_subnets

  # Labels
  labels = var.labels

  # State Bucket
  bucket_project       = var.bucket_project != "" ? var.bucket_project : module.project_factory.project_id
  bucket_name          = var.bucket_name != "" ? var.bucket_name : "${module.project_factory.project_name}-tfstate"
  bucket_location      = var.bucket_location
  bucket_versioning    = var.bucket_versioning
  bucket_labels        = var.bucket_labels
  bucket_force_destroy = var.bucket_force_destroy
  bucket_ula           = var.bucket_ula
  bucket_pap           = var.bucket_pap

  # Auto Network
  auto_create_network = var.auto_create_network

  # Destruction
  lien                        = var.lien
  disable_services_on_destroy = var.disable_services_on_destroy
  default_service_account     = var.default_service_account
  disable_dependent_services  = var.disable_dependent_services

  # Budget
  budget_amount                           = var.budget_amount
  budget_display_name                     = var.budget_display_name
  budget_alert_pubsub_topic               = var.budget_alert_pubsub_topic
  budget_monitoring_notification_channels = var.budget_monitoring_notification_channels
  budget_alert_spent_percents             = var.budget_alert_spent_percents
  budget_alert_spend_basis                = var.budget_alert_spend_basis
  budget_labels                           = var.budget_labels
  budget_calendar_period                  = var.budget_calendar_period
  budget_custom_period_start_date         = var.budget_custom_period_start_date
  budget_custom_period_end_date           = var.budget_custom_period_end_date

  # VPC Service Control
  vpc_service_control_attach_enabled = var.vpc_service_control_attach_enabled
  vpc_service_control_attach_dry_run = var.vpc_service_control_attach_dry_run
  vpc_service_control_perimeter_name = var.vpc_service_control_perimeter_name
  vpc_service_control_sleep_duration = var.vpc_service_control_sleep_duration

  # Default Service Agent Roles
  grant_services_security_admin_role = var.grant_services_security_admin_role
  grant_network_role                 = var.grant_network_role

  # Consumer Quotas
  consumer_quotas = var.consumer_quotas

  # Default Network Tier
  default_network_tier = var.default_network_tier

  # Essential Contacts
  essential_contacts = var.essential_contacts

  # Language Tag
  language_tag = var.language_tag

  # Tag Binding Values
  tag_binding_values = var.tag_binding_values

  # Cloud Armor Tier
  cloud_armor_tier = var.cloud_armor_tier

  # Deletion Policy
  deletion_policy = var.deletion_policy
}

# Service Account for Tofu to use for provisioning
resource "google_service_account" "tofu_provisioner_sa" {
  project      = module.project_factory.project_id
  account_id   = var.tofu_sa_name
  description  = var.tofu_sa_description != null ? var.tofu_sa_description : "Service account for OpenTofu to manage resources in project ${module.project_factory.project_id}"

  depends_on = [module.project_factory]
}

# Grant Tofu Provisioner SA roles on the project, making sure it is the ONLY owner. This removes ownership from the Tofu orchestrator that provisions our projects from the infrastructure repo.
resource "google_project_iam_binding" "tofu_provisioner_sa_project_roles" {
  for_each = toset(var.tofu_provisioner_sa_project_roles)

  project = module.project_factory.project_id
  role    = each.key

  members = [
    "serviceAccount:${google_service_account.tofu_provisioner_sa[0].email}" # Access via index due to count
  ]

  depends_on = [google_service_account.tofu_provisioner_sa]
}

# Grant Tofu Provisioner SA access to the Tofu state bucket
resource "google_storage_bucket_iam_member" "tofu_provisioner_sa_state_bucket_access" {
  count = var.enable_tofu_backend_setup ? 1 : 0

  bucket = google_storage_bucket.tofu_state_bucket[0].name                         # Access via index due to count
  role   = "roles/storage.objectAdmin"                                             # Full control over objects in the bucket
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
  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool[0].name}/attribute.repository/${var.github_repository}"
  ]

  depends_on = [
    google_iam_workload_identity_pool_provider.github_provider,
    google_service_account.tofu_provisioner_sa
  ]
}

