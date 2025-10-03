# GCP Project Factory

An opinionated wrapper around the [terraform-google-modules/terraform-google-project-factory](https://github.com/terraform-google-modules/terraform-google-project-factory) that provides sensible defaults for OpenJustice OK projects.

## Features

- **Battle-tested foundation**: Built on the widely-used terraform-google-modules project factory
- **Opinionated defaults**: Pre-configured with APIs and settings commonly needed by OpenJustice OK
- **Service account management**: Automatic creation of a Tofu-specific service account with a configurable role.
- **OpenTofu backend support**: Creates a GCS bucket for OpenTofu state management.
- **Workload Identity Federation**: Securely allows GitHub Actions to impersonate the Tofu service account.
- **Security best practices**: Removes default service account, disables auto-network creation

## Usage

```hcl
module "project_factory" {
  source = "../../../modules/gcp/project-factory"

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
| `enable_wif` | If true, creates Workload Identity Federation resources to allow GitHub Actions to impersonate the Tofu provisioner service account. | `bool` | `false` | no |
| `github_repository` | The GitHub repository (in 'owner/repo' format) that should be allowed to impersonate the Tofu provisioner service account via WIF. Required if enable_wif is true. | `string` | `null` | no |
| `wif_pool_id` | The ID for the Workload Identity Pool. | `string` | `"github-actions-pool"` | no |
| `wif_provider_id` | The ID for the Workload Identity Provider within the pool. | `string` | `"github-provider"` | no |

## Outputs

| Name | Description |
|------|-------------|
| `project_id` | The ID of the created project. |
| `project_number` | The number of the created project. |
| `project_name` | The name of the created project. |
| `tofu_sa_email` | The email of the Tofu service account. |
| `tofu_state_bucket_name` | The name of the Tofu state bucket. |
| `wif_pool_name` | The name of the WIF pool. |
| `wif_provider_name` | The name of the WIF provider. |