# GCP Project Factory

An opinionated wrapper around the [terraform-google-modules/terraform-google-project-factory](https://github.com/terraform-google-modules/terraform-google-project-factory) that provides sensible defaults for OpenJustice OK projects.

## Features

- **Battle-tested foundation**: Built on the widely-used terraform-google-modules project factory
- **Opinionated defaults**: Pre-configured with APIs and settings commonly needed by OpenJustice OK
- **Service account management**: Automatic creation of a Tofu-specific service account with a configurable role.
- **OpenTofu backend support**: Creates a GCS bucket for OpenTofu state management.
- **Workload Identity Federation**: Securely allows GitHub Actions to impersonate the Tofu service account.
- **Cross-Project Artifact Access** (v0.7.0+): Use `cross_project_artifact_access` input variable to grant this project's provisioner SA read access to other projects' Artifact Registries and GCS buckets. Best for **single-project use cases** - for multi-environment setups, use `environment-factory` with `enable_cross_env_artifacts` instead.
- **Security best practices**: Removes default service account, disables auto-network creation

## Usage

### Basic Usage

```hcl
module "project_factory" {
  source = "github.com/openjusticeok/tofu-modules//modules/gcp/project-factory?ref=v0.7.0"

  # Required
  name            = "my-project"
  billing_account = "012345-6789AB-CDEF01"
  
  # Recommended
  folder_id       = "folders/123456789012"
  
  # Tofu SA
  tofu_sa_name = "my-tofu-sa"
  tofu_sa_role = "roles/editor"
  
  # WIF
  enable_wif        = true
  github_repository = "my-org/my-repo"

  labels = {
    environment = "production"
    team        = "infrastructure"
  }
}
```

### With Cross-Project Artifact Access (v0.7.0+)

**Use case**: Single project that needs to copy container images or GCE disk images from another project (e.g., a standalone prod project reading from an external dev project).

⚠️ **Note**: If you're creating multiple environments (dev/stg/prod) together, use `environment-factory` with `enable_cross_env_artifacts = true` instead. That module handles cross-project access automatically with standalone IAM resources to avoid circular dependencies.

```hcl
module "project_factory" {
  source = "github.com/openjusticeok/tofu-modules//modules/gcp/project-factory?ref=v0.7.0"

  name            = "my-project-prod"
  billing_account = "012345-6789AB-CDEF01"
  folder_id       = "folders/123456789012"

  # WIF Configuration
  enable_wif        = true
  wif_pool_name     = "projects/12345/locations/global/workloadIdentityPools/github-pool"
  github_repository = "my-org/my-app"

  # Cross-project artifact access - for single projects that need to read from external sources
  # This grants THIS project's provisioner SA read access to OTHER projects' resources
  cross_project_artifact_access = [
    {
      project_id   = "external-project-dev-abcd"    # External project to read from
      location     = "us-central1"                   # Artifact Registry location
      repository   = "repo"                          # Artifact Registry repository name
      bucket_name  = "external-project-nixos-images" # GCS bucket for GCE images
    }
  ]

  labels = {
    environment = "production"
    team        = "infrastructure"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | The name for the project. | `string` | n/a | yes |
| `billing_account` | The ID of the billing account to associate this project with. | `string` | n/a | yes |
| `folder_id` | The ID of a folder to host this project. | `string` | `""` | no |
| `org_id` | The organization ID. | `string` | `null` | no |
| `labels` | Map of labels for project. | `map(string)` | `{}` | no |
| `activate_apis` | The list of apis to activate within the project. | `list(string)` | See `variables.tf` | no |
| `tofu_sa_name` | OpenTofu Provisioner service account name for the project. | `string` | `"tofu-provisioner"` | no |
| `tofu_sa_role` | A role to give the OpenTofu Provisioner Service Account for the project. | `string` | `"roles/owner"` | no |
| `enable_wif` | If true, creates IAM binding to allow GitHub Actions to impersonate the Tofu provisioner service account via the global WIF pool. | `bool` | `false` | no |
| `github_repository` | The GitHub repository (in 'owner/repo' format) that should be allowed to impersonate the Tofu provisioner service account via WIF. Required if enable_wif is true. | `string` | `null` | no |
| `wif_pool_name` | The full resource name of the global Workload Identity Pool from openjusticeok/infrastructure (e.g., 'projects/12345/locations/global/workloadIdentityPools/github-pool'). Required if enable_wif is true. | `string` | `null` | no |
| `cross_project_artifact_access` | **(v0.7.0+)** List of external projects to grant artifact registry and GCS read access for promotion workflows. Grants THIS project's provisioner SA read access to OTHER projects' resources. **For multi-environment setups, use environment-factory with enable_cross_env_artifacts instead.** | `list(object)` | `[]` | no |

### cross_project_artifact_access Object

When `cross_project_artifact_access` is specified, each object in the list should have:

| Field | Description | Type |
|-------|-------------|------|
| `project_id` | The GCP project ID to grant access to | `string` |
| `location` | The GCP region where the Artifact Registry is located | `string` |
| `repository` | The name of the Artifact Registry repository | `string` |
| `bucket_name` | The name of the GCS bucket containing GCE images | `string` |

This grants the current project's `tofu-provisioner` service account:
- `roles/artifactregistry.reader` on the external project's Artifact Registry repository
- `roles/storage.objectViewer` on the external project's GCS bucket

## Outputs

| Name | Description |
|------|-------------|
| `project_id` | The ID of the created project. |
| `project_number` | The number of the created project. |
| `project_name` | The name of the created project. |
| `tofu_sa_email` | The email of the Tofu service account. |
| `tofu_state_bucket_name` | The name of the Tofu state bucket. |
| `wif_pool_name` | The global WIF pool name passed to this module. Only set if enable_wif is true. |
| `github_actions_sa_email` | The service account email for GitHub Actions to impersonate. Only set if enable_wif is true. |
