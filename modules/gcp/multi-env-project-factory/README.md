# GCP Multi-Environment Project Factory

This module provides an opinionated way to set up multiple Google Cloud Platform (GCP) projects for different environments (e.g., `dev`, `staging`, `prod`) within a dedicated GCP folder.
It leverages the enhanced `project-factory` module to provision each project with secure Workload Identity Federation (WIF) for GitHub Actions.

## Features

-   **Dedicated Folder Creation**: Automatically creates a new GCP folder to house all environment-specific projects, promoting organization and isolation.
-   **Multi-Environment Provisioning**: Creates a set of GCP projects (e.g., `dev`, `staging`, `prod`) based on a configurable map of environments.
-   **Leverages Enhanced `project-factory`**: Each project is provisioned using the `project-factory` module, inheriting its features like Tofu backend setup and enhanced WIF.
-   **Branch-Aware CI/CD Integration**: Configures Workload Identity Federation for each project, allowing GitHub Actions to perform branch-specific `plan` (read-only) and `apply` (full control) operations.
-   **Scalable and Reusable**: Designed to be easily integrated into your infrastructure-as-code repository to quickly spin up new application environments.

## Usage

This module is typically called from your main infrastructure repository (e.g., `openjusticeok/infrastructure`).

```hcl
module "my_application_environments" {
  source = "github.com/openjusticeok/tofu-modules//modules/gcp/multi-env-project-factory?ref=main" # Or a specific tag/commit hash

  # Required
  parent_id           = "organizations/YOUR_ORGANIZATION_ID" # Replace with your actual organization ID or parent folder ID
  folder_display_name = "My Application Environments"        # Display name for the new folder
  project_name_prefix = "my-app"                             # e.g., will create my-app-dev, my-app-staging, my-app-prod
  billing_account     = "YOUR_BILLING_ACCOUNT_ID"            # Replace with your actual billing account ID
  github_repo         = "openjusticeok/infrastructure"       # Your infrastructure repository (owner/repo format)

  # Optional: Override default environments or add more
  # environments = {
  #   "dev"     = { branch_name = "dev" },
  #   "staging" = { branch_name = "staging" },
  #   "prod"    = { branch_name = "main" },
  #   "qa"      = { branch_name = "qa" }
  # }

  # Optional: Override default plan_branch_pattern (default is "refs/pull/*")
  # plan_branch_pattern = "refs/heads/feature/*"

  # Optional: Tofu state bucket location (default is "US-CENTRAL1")
  # tofu_state_bucket_location = "us-east1"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent_id` | The ID of the parent resource (organization or folder) to create the new folder in. E.g., `organizations/12345` or `folders/67890`. | `string` | n/a | yes |
| `folder_display_name` | The display name for the new folder that will contain the environment projects. | `string` | n/a | yes |
| `project_name_prefix` | A prefix for all created project names and IDs. e.g., `my-app` will create `my-app-dev`, `my-app-staging`, etc. | `string` | n/a | yes |
| `billing_account` | The ID of the billing account to link to the created projects. | `string` | n/a | yes |
| `github_repo` | The GitHub repository in `owner/repo` format that will be granted access to the projects via WIF. | `string` | n/a | yes |
| `environments` | A map of environments to create, with their corresponding GitHub branch for `apply` operations. | `map(object({ branch_name = string }))` | See variables.tf | no |
| `plan_branch_pattern` | The Git branch pattern (e.g., `refs/pull/*`) that is allowed to impersonate the **planner** service account (for `tofu plan`) across all environments. | `string` | `"refs/pull/*"` | no |
| `tofu_state_bucket_location` | The location for the Tofu state GCS bucket for all projects (e.g., `US-CENTRAL1`). | `string` | `"US-CENTRAL1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| `folder_id` | The ID of the GCP folder created for the environments. |
| `project_ids` | A map of project IDs created, keyed by environment name. |
| `applier_sa_emails` | A map of applier service account emails, keyed by environment name. |
| `planner_sa_emails` | A map of planner service account emails, keyed by environment name. |

## CI/CD Integration

This module sets up Workload Identity Federation for each created project, allowing your GitHub Actions workflows to securely authenticate and manage resources.

Use the `applier_sa_emails` and `planner_sa_emails` outputs to configure your GitHub Actions workflows. For example, if you have `dev`, `staging`, and `prod` environments:

-   **`dev` environment**: Use `module.my_application_environments.applier_sa_emails["dev"]` for `apply` operations on the `dev` branch.
-   **`staging` environment**: Use `module.my_application_environments.applier_sa_emails["staging"]` for `apply` operations on the `staging` branch.
-   **`prod` environment**: Use `module.my_application_environments.applier_sa_emails["prod"]` for `apply` operations on the `main` branch.
-   **All environments**: Use `module.my_application_environments.planner_sa_emails["dev"]` (or any other environment's planner SA) for `plan` operations on PR branches.

Refer to the `project-factory` module's documentation for detailed GitHub Actions workflow examples.
