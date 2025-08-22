# GCP Project Factory

An opinionated wrapper around the [terraform-google-modules/terraform-google-project-factory](https://github.com/terraform-google-modules/terraform-google-project-factory) that provides sensible defaults for OpenJustice OK projects.

## Features

- **Battle-tested foundation**: Built on the widely-used terraform-google-modules project factory
- **Opinionated defaults**: Pre-configured with APIs and settings commonly needed by OpenJustice OK
- **Service account management**: Automatic creation of a general-purpose service account with configurable roles
- **OpenTofu backend support**: Optional setup of GCS bucket and dedicated service account for OpenTofu state management
- **Security best practices**: Removes default service account, disables auto-network creation

## Key Differences from Upstream

This module wraps the upstream terraform-google-modules project factory with the following opinionated changes:

- **Auto-network creation disabled**: Encourages explicit network management
- **Default service account removed**: Better security posture by removing the overprivileged default SA
- **Opinionated API list**: Includes commonly needed APIs for our infrastructure use cases
- **OpenTofu-specific features**: Built-in support for OpenTofu state backend setup
- **Simplified interface**: Exposes commonly-used variables while maintaining flexibility

## Usage

### Basic Usage

```hcl
module "project_factory" {
  source = "../../../modules/gcp/project-factory"

  # Required
  project_id      = "my-project-12345"
  billing_account = "012345-6789AB-CDEF01"
  
  # Recommended
  folder_id       = "folders/123456789012"
  
  # Service Account
  service_account_id = "my-app-sa"
  
  labels = {
    environment = "production"
    team        = "infrastructure"
  }
}
```

### With OpenTofu Backend Setup

```hcl
module "project_factory" {
  source = "../../../modules/gcp/project-factory"

  project_id      = "my-project-12345"
  billing_account = "012345-6789AB-CDEF01"
  folder_id       = "folders/123456789012"
  
  service_account_id = "my-app-sa"
  
  # Enable OpenTofu backend resources
  enable_tofu_backend_setup     = true
  tofu_state_bucket_location    = "US-CENTRAL1"
  tofu_provisioner_sa_project_roles = ["roles/owner"]
  
  labels = {
    environment = "production"
    team        = "infrastructure"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `project_id` | The desired ID for the new GCP project | `string` | n/a | yes |
| `billing_account` | The ID of the billing account to associate with the project | `string` | n/a | yes |
| `project_name` | The display name for the new GCP project | `string` | `null` (uses project_id) | no |
| `folder_id` | The ID of the folder to create the project in | `string` | `null` | no |
| `org_id` | The ID of the organization to create the project in | `string` | `null` | no |
| `labels` | A map of labels to apply to the project | `map(string)` | `{}` | no |
| `activate_apis` | A list of APIs to enable on the project | `list(string)` | See variables.tf | no |
| `service_account_id` | The desired ID for the general-purpose service account | `string` | n/a | yes |
| `service_account_project_roles` | Project-level IAM roles to grant to the service account | `list(string)` | `["roles/viewer"]` | no |
| `enable_tofu_backend_setup` | If true, creates GCS bucket and provisioner SA for OpenTofu | `bool` | `false` | no |
| `tofu_state_bucket_name_suffix` | Suffix for the OpenTofu state bucket name | `string` | `"tfstate"` | no |
| `tofu_state_bucket_location` | Location for the OpenTofu state GCS bucket | `string` | `"US-CENTRAL1"` | no |
| `tofu_provisioner_sa_project_roles` | Project-level IAM roles for the OpenTofu provisioner SA | `list(string)` | `["roles/owner"]` | no |

## Outputs

| Name | Description |
|------|-------------|
| `project_id` | The ID of the created GCP project |
| `project_number` | The number of the created GCP project |
| `project_name` | The name of the created GCP project |
| `generic_service_account_email` | The email address of the created service account |
| `generic_service_account_unique_id` | The unique ID of the created service account |
| `generic_service_account_name` | The full name of the created service account |
| `enabled_apis` | List of APIs enabled on the project |
| `tofu_state_bucket_name` | The name of the GCS bucket for OpenTofu state (if enabled) |
| `tofu_state_bucket_url` | The gsutil URL of the GCS bucket for OpenTofu state (if enabled) |
| `tofu_provisioner_sa_email` | The email address of the OpenTofu provisioner service account (if enabled) |
| `tofu_provisioner_sa_unique_id` | The unique ID of the OpenTofu provisioner service account (if enabled) |

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

## Requirements

| Name | Version |
|------|---------|
| terraform/tofu | >= 1.0 |
| google | ~> 6.0 |

## Examples

See the [example](../../../examples/gcp/project-factory-example/main.tf) for a complete usage demonstration.