# GCP Environment Factory

This Terraform module creates a complete, multi-environment setup in Google Cloud Platform. It provisions a new folder and then uses the `project-factory` module to create a set of projects within it, one for each specified environment (e.g., `dev`, `stg`, `prod`).

This approach ensures that each environment is isolated, consistently configured, and ready for use with CI/CD pipelines.

## Features

- **Automated Folder Creation**: Creates a new GCP folder to house all environment-specific projects, keeping your resource hierarchy organized.
- **Multi-Environment Project Scaffolding**: Dynamically creates a project for each environment listed in the `environments` variable.
- **Consistent Project Configuration**: Leverages the `project-factory` module to ensure each project is set up with:
  - A secure, Tofu-specific service account.
  - Pre-configured Workload Identity Federation for GitHub Actions.
  - An OpenTofu remote backend GCS bucket.
  - A curated list of commonly used APIs.
- **Customizable**: Easily customize project names, labels, enabled APIs, and service account roles.
- **Secure by Default**: Builds on the security best practices of the underlying `project-factory` module.

## Usage

```hcl
module "environment_factory" {
  source = "github.com/openjusticeok/tofu-modules//modules/gcp/environment-factory"

  # Naming and Organization
  name                  = "my-cool-app"
  folder_display_name   = "My Cool App Environments"
  parent                = "organizations/123456789012" # Can also be a folder ID
  billing_account       = "012345-6789AB-CDEF01"

  # Environments to create
  environments = ["dev", "stg", "prod"]

  # GitHub Actions Integration
  github_repository = "my-github-org/my-cool-app-repo"

  # Optional: Customizations
  tofu_sa_role = "roles/editor"
  
  labels = {
    "created-by" = "tofu-module"
    "app"        = "my-cool-app"
  }

  activate_apis = [
    "compute.googleapis.com",
    "storage.googleapis.com",
    "iam.googleapis.com",
    "run.googleapis.com" # Add Cloud Run API
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name` | A name for all created project names and IDs. e.g., 'my-app' will create 'my-app-dev', 'my-app-staging', etc. | `string` | n/a | yes |
| `folder_display_name` | The display name for the new folder that will contain the environment projects. | `string` | n/a | yes |
| `billing_account` | The GCP billing account ID to link to the created projects. | `string` | n/a | yes |
| `parent` | The ID of the parent resource (organization or folder) to create the new folder in. E.g., 'organizations/12345' or 'folders/67890'. | `string` | n/a | yes |
| `github_repository` | The GitHub repository in 'owner/repo' format that will be granted access for Workload Identity Federation. | `string` | n/a | yes |
| `environments` | A list of environments to create projects for. | `list(string)` | `["dev", "stg", "prod"]` | no |
| `labels` | A map of labels to apply to each created project. | `map(string)` | `{}` | no |
| `activate_apis` | A list of APIs to enable on each created project. | `list(string)` | See `variables.tf` | no |
| `tofu_sa_name` | OpenTofu Provisioner service account name for the project. | `string` | `"tofu-provisioner"` | no |
| `tofu_sa_role` | A role to give the OpenTofu Provisioner Service Account for the project. | `string` | `"roles/owner"` | no |

## Outputs

| Name | Description |
|------|-------------|
| `folder` | The full `google_folder` resource that was created. |
| `projects` | A map of the full `project-factory` module outputs for each environment created. You can access the outputs of a specific project using its environment name as the key (e.g., `module.environment_factory.projects["dev"]`). |
| `project_ids` | A map of the project IDs for each environment, keyed by environment name. |
| `tofu_sa_emails` | A map of the Tofu service account email addresses for each environment, keyed by environment name. |
| `tofu_state_buckets` | A map of the GCS bucket names created for the OpenTofu backend for each environment, keyed by environment name. |