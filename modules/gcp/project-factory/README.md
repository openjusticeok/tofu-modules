# GCP Project Factory

An opinionated wrapper around the [terraform-google-modules/terraform-google-project-factory](https://github.com/terraform-google-modules/terraform-google-project-factory) that provides sensible defaults for OpenJustice OK projects.

## Features

- **Battle-tested foundation**: Built on the widely-used terraform-google-modules project factory
- **Opinionated defaults**: Pre-configured with APIs and settings commonly needed by OpenJustice OK
- **Service account management**: Automatic creation of general-purpose and Tofu-specific service accounts with configurable roles
- **OpenTofu backend support**: Optional setup of GCS bucket and dedicated service accounts for OpenTofu state management
- **Enhanced Workload Identity Federation**: Securely allows GitHub Actions to perform branch-specific `plan` (read-only) and `apply` (full control) operations on GCP resources.
- **Security best practices**: Removes default service account, disables auto-network creation

## Key Differences from Upstream

This module wraps the upstream terraform-google-modules project factory with the following opinionated changes:

- **Auto-network creation disabled**: Encourages explicit network management
- **Default service account removed**: Better security posture by removing the overprivileged default SA
- **Opinionated API list**: Includes commonly needed APIs for our infrastructure use cases
- **OpenTofu-specific features**: Built-in support for OpenTofu state backend setup
- **WIF integration**: Built-in Workload Identity Federation setup for GitHub Actions
- **Simplified interface**: Exposes commonly-used variables while maintaining flexibility

## Usage

### Basic Usage

```hcl
module "project_factory" {
  source = "../../../modules/gcp/project-factory"

  # Required
  project_name    = "my-project"
  billing_account = "012345-6789AB-CDEF01"
  
  # Recommended
  folder_id       = "folders/123456789012"
  
  # Service Account
  user_service_account_id = "my-app-sa"
  user_service_account_project_role = "roles/editor" # Example role
  
  labels = {
    environment = "production"
    team        = "infrastructure"
  }
}
```

### With OpenTofu Backend Setup and Enhanced WIF

This example demonstrates how to enable the OpenTofu backend setup and configure Workload Identity Federation for branch-based `plan` and `apply` permissions.

```hcl
module "project_factory" {
  source = "../../../modules/gcp/project-factory"

  project_name    = "my-project"
  billing_account = "012345-6789AB-CDEF01"
  folder_id       = "folders/123456789012"
  
  user_service_account_id = "my-app-sa"
  
  # Enable OpenTofu backend resources
  enable_tofu_backend_setup     = true
  tofu_state_bucket_location    = "US-CENTRAL1"
  tofu_provisioner_sa_project_roles = ["roles/owner"] # This applies to the applier SA
  
  # Enable Enhanced WIF for GitHub Actions
  enable_wif             = true
  github_repository      = "myorg/my-project-repo"
  apply_branch_pattern   = "refs/heads/main" # Only 'main' branch can apply
  plan_branch_pattern    = "refs/pull/*"     # All PR branches can plan
  wif_pool_id            = "github-actions-pool"
  wif_provider_id        = "github-provider"
  
  labels = {
    environment = "production"
    team        = "infrastructure"
  }
}

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `project_name` | The display name for the new GCP project. This will be used to create a unique project id unless specified. | `string` | n/a | yes |
| `project_id` | Optional. Specify a custom project ID to override the generated one. If not set, an ID will be generated from the project_name. | `string` | `null` | no |
| `billing_account` | The ID of the billing account to associate with the project | `string` | n/a | yes |
| `folder_id` | The ID of the folder to create the project in | `string` | `null` | no |
| `org_id` | The ID of the organization to create the project in | `string` | `null` | no |
| `labels` | A map of labels to apply to the project | `map(string)` | `{}` | no |
| `activate_apis` | A list of APIs to enable on the project | `list(string)` | See variables.tf | no |
| `user_service_account_id` | The desired ID for the new general-purpose service account (e.g., 'my-app-sa'). This will be the part before '@'. | `string` | n/a | yes |
| `user_service_account_project_role` | A project-level IAM role to grant to the general-purpose service account (e.g., 'roles/viewer', 'roles/editor'). | `string` | `"roles/viewer"` | no |
| `enable_tofu_backend_setup` | If true, creates a GCS bucket for Tofu state and dedicated Tofu provisioner service accounts (applier and planner). | `bool` | `false` | no |
| `tofu_state_bucket_name_suffix` | A suffix to append to the project ID to form the Tofu state bucket name. The final name will be '<project_id>-<suffix>-tfstate'. If empty, '-tfstate' will be used. | `string` | `"tfstate"` | no |
| `tofu_state_bucket_location` | The location for the Tofu state GCS bucket (e.g., 'US-CENTRAL1'). | `string` | `"US-CENTRAL1"` | no |
| `tofu_provisioner_sa_project_roles` | A list of project-level IAM roles to grant to the Tofu **applier** service account. **Warning:** This uses `google_project_iam_binding` and will overwrite any existing IAM bindings for the specified roles. | `list(string)` | `["roles/owner"]` | no |
| `enable_wif` | If true, creates Workload Identity Federation resources to allow GitHub Actions to impersonate the Tofu applier and planner service accounts. Requires `enable_tofu_backend_setup` to be true. | `bool` | `false` | no |
| `github_repository` | The GitHub repository (in 'owner/repo' format) that should be allowed to impersonate the Tofu service accounts via WIF. Required if `enable_wif` is true. | `string` | `null` | no |
| `apply_branch_pattern` | The Git branch pattern (e.g., `refs/heads/main`) that is allowed to impersonate the **applier** service account (for `tofu apply`). Required if `enable_wif` is true. | `string` | `"refs/heads/main"` | no |
| `plan_branch_pattern` | The Git branch pattern (e.g., `refs/pull/*`) that is allowed to impersonate the **planner** service account (for `tofu plan`). Required if `enable_wif` is true. | `string` | `"refs/pull/*"` | no |
| `wif_pool_id` | The ID for the Workload Identity Pool. | `string` | `"github-actions-pool"` | no |
| `wif_provider_id` | The ID for the Workload Identity Provider within the pool. | `string` | `"github-provider"` | no |

## Outputs

| Name | Description |
|------|-------------|
| `project_id` | The ID of the created GCP project |
| `project_number` | The number of the created GCP project |
| `project_name` | The name of the created GCP project |
| `generic_service_account_email` | The email address of the created general-purpose service account |
| `generic_service_account_unique_id` | The unique ID of the created general-purpose service account |
| `generic_service_account_name` | The full name of the created general-purpose service account |
| `enabled_apis` | List of APIs enabled on the project |
| `tofu_state_bucket_name` | The name of the GCS bucket for OpenTofu state (if enabled) |
| `tofu_state_bucket_url` | The gsutil URL of the GCS bucket for OpenTofu state (if enabled) |
| `tofu_provisioner_sa_email` | The email address of the OpenTofu **applier** service account (if enabled) |
| `tofu_provisioner_sa_unique_id` | The unique ID of the OpenTofu **applier** service account (if enabled) |
| `tofu_planner_sa_email` | The email address of the OpenTofu **planner** service account (if enabled) |
| `wif_pool_name` | The full name of the Workload Identity Pool (if WIF enabled) |
| `wif_provider_name` | The full name of the Workload Identity Provider (if WIF enabled) |
| `wif_audience` | The audience value to use in GitHub Actions for WIF authentication (if WIF enabled) |

## Default APIs

The module enables these APIs by default:

- `compute.googleapis.com`
- `storage.googleapis.com`
- `iam.googleapis.com`
- `cloudresourcemanager.googleapis.com`
- `serviceusage.googleapis.com`
- `iamcredentials.googleapis.com`
- `logging.googleapis.com`
- `monitoring.googleapis.com`

You can extend this list by providing additional APIs in the `activate_apis` variable.

## OpenTofu Backend Setup

When `enable_tofu_backend_setup` is `true`, the module creates:

1. **GCS Bucket**: For storing OpenTofu state files with versioning enabled
2. **Provisioner Service Account**: Dedicated SA for OpenTofu to use for provisioning
3. **IAM Bindings**: Grants the provisioner SA appropriate permissions

This setup follows best practices for OpenTofu state management in GCP.

**Warning:** The `tofu_provisioner_sa_project_roles` variable uses `google_project_iam_binding`. This will overwrite any existing IAM bindings for the roles you specify. For example, if you use the default `["roles/owner"]`, the Tofu provisioner service account will become the *sole* owner of the project, removing any other owners.

## Workload Identity Federation (WIF)

When both `enable_tofu_backend_setup` and `enable_wif` are `true`, the module creates:

1.  **Workload Identity Pool**: Container for WIF providers.
2.  **GitHub OIDC Provider**: Configures GitHub as a trusted identity provider, capable of identifying the repository and Git branch/ref.
3.  **IAM Bindings**: Configures two distinct sets of permissions for GitHub Actions based on the Git branch:
    *   **Applier Role**: Allows the specified `apply_branch_pattern` (e.g., `refs/heads/main`) to impersonate the **applier** service account (which has `roles/owner` on the project). This is for `terraform apply` operations.
    *   **Planner Role**: Allows the specified `plan_branch_pattern` (e.g., `refs/pull/*`) to impersonate the **planner** service account (which has `roles/viewer` on the project). This is for `terraform plan` operations.

This enables GitHub Actions to securely authenticate to GCP without storing service account keys, with fine-grained control over permissions based on the Git branch.

### GitHub Actions Configuration

After enabling WIF, configure your GitHub Actions workflows to use the appropriate service account based on the operation (`plan` or `apply`) and the Git branch.

**1. Plan Workflow (e.g., on `pull_request`):**

```yaml
name: Terraform Plan
on:
  pull_request:
    branches:
      - '*' # Run on all pull requests

jobs:
  plan:
    runs-on: ubuntu-latest
    permissions:
      contents: 'read'
      id-token: 'write' # Required for Workload Identity Federation

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - id: 'auth'
        uses: 'google-github-actions/auth@v2'
        with:
          # Use the WIF_PROVIDER_NAME output from the project-factory module
          workload_identity_provider: ${{ vars.WIF_PROVIDER_NAME }}
          # Use the tofu_planner_sa_email output from the project-factory module
          service_account: ${{ vars.TOFU_PLANNER_SA_EMAIL }}

      - name: 'Set up Tofu'
        uses: 'hashicorp/setup-terraform@v3'
        with:
          terraform_version: '1.6.0' # Or your desired version

      - name: 'Tofu Init'
        run: tofu init

      - name: 'Tofu Plan'
        run: tofu plan
```

**2. Apply Workflow (e.g., on `push` to `main`, `staging`, `dev`):**

```yaml
name: Terraform Apply
on:
  push:
    branches:
      - main
      - staging
      - dev # Or any other branch matching your apply_branch_pattern

jobs:
  apply:
    runs-on: ubuntu-latest
    permissions:
      contents: 'read'
      id-token: 'write'

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - id: 'auth'
        uses: 'google-github-actions/auth@v2'
        with:
          # Use the WIF_PROVIDER_NAME output from the project-factory module
          workload_identity_provider: ${{ vars.WIF_PROVIDER_NAME }}
          # Use the tofu_provisioner_sa_email output from the project-factory module
          service_account: ${{ vars.TOFU_PROVISIONER_SA_EMAIL }}

      - name: 'Set up Tofu'
        uses: 'hashicorp/setup-terraform@v3'
        with:
          terraform_version: '1.6.0'

      - name: 'Tofu Init'
        run: tofu init

      - name: 'Tofu Apply'
        run: tofu apply -auto-approve
```

**Configure the following repository variables in GitHub:**

*   `WIF_PROVIDER_NAME`: Value from the `wif_provider_name` output of the `project-factory` module.
*   `TOFU_PROVISIONER_SA_EMAIL`: Value from the `tofu_provisioner_sa_email` output of the `project-factory` module.
*   `TOFU_PLANNER_SA_EMAIL`: Value from the `tofu_planner_sa_email` output of the `project-factory` module.

## Requirements

| Name | Version |
|------|---------|
| tofu | >= 1.0 |
| google | ~> 6.0 |

## Examples

See the [example](../../examples/gcp/project-factory-example/main.tf) for a complete usage demonstration.