# GCP Environment Factory

This Terraform module creates a complete, multi-environment setup in Google Cloud Platform. It provisions a new folder and then uses the `project-factory` module to create a set of projects within it, one for each specified environment (e.g., `dev`, `stg`, `prod`).

This approach ensures that each environment is isolated, consistently configured, and ready for use with CI/CD pipelines.

## Features

- **Automated Folder Creation**: Creates a new GCP folder to house all environment-specific projects, keeping your resource hierarchy organized.
- **Multi-Environment Project Scaffolding**: Dynamically creates a project for each environment listed in the `environments` variable.
- **Consistent Project Setup**: Leverages the `project-factory` module to ensure each project has the same core configuration, including:
  - A secure, Tofu-specific service account.
  - Pre-configured Workload Identity Federation for GitHub Actions.
  - An OpenTofu remote backend GCS bucket.
  - A curated list of commonly used APIs.
- **Customizable**: Easily customize project names, labels, enabled APIs, and service account roles.
- **Secure by Default**: Builds on the security best practices of the underlying `project-factory` module.
- **Cross-Environment Artifact Promotion** (v0.7.0+): Enable `enable_cross_env_artifacts = true` to automatically create standalone IAM resources that grant each environment read access to all lower environments. Perfect for CI/CD pipelines that promote artifacts from dev → stg → prod without rebuilding.

## Cross-Environment Artifact Promotion (v0.7.0+)

When you enable `enable_cross_env_artifacts = true`, the module automatically creates a waterfall promotion chain using **standalone IAM resources** (not module inputs):

- **prod** (index 2): Can read artifacts from **stg** (index 1) and **dev** (index 0)
- **stg** (index 1): Can read artifacts from **dev** (index 0)
- **dev** (index 0): No cross-project access (lowest environment)

### Why Standalone Resources?

The cross-project IAM bindings are created as **standalone resources** that depend on all projects being created first. This avoids circular dependency issues that would occur if we passed cross-project references as inputs to the project-factory module (which would create a cycle: module needs input → input references module output).

This enables CI/CD workflows that:
1. Build and test artifacts in `dev`
2. Copy artifacts from `dev` to `stg` for staging testing  
3. Copy artifacts from `stg` (or `dev`) to `prod` for production deployment

All without rebuilding, ensuring immutable, traceable deployments.

## Usage

### Standard Multi-Environment Setup

```hcl
module "environment_factory" {
  source = "github.com/openjusticeok/tofu-modules//modules/gcp/environment-factory?ref=v0.7.0"

  # Naming and Organization
  name                  = "my-cool-app"
  folder_display_name   = "My Cool App Environments"
  parent                = "organizations/123456789012" # Can also be a folder ID
  billing_account       = "012345-6789AB-CDEF01"

  # Environments to create
  environments = ["dev", "stg", "prod"]

  # GitHub Actions Integration
  github_repository = "my-github-org/my-cool-app-repo"

  # Hub & Spoke: Pass the global WIF pool from openjusticeok/infrastructure
  wif_pool_name = "projects/12345/locations/global/workloadIdentityPools/github-pool"

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

### With Cross-Environment Artifact Promotion (v0.7.0+)

Enable this when you want to promote container images or GCE disk images between environments:

```hcl
module "environment_factory" {
  source = "github.com/openjusticeok/tofu-modules//modules/gcp/environment-factory?ref=v0.7.0"

  # Naming and Organization
  name                  = "my-cool-app"
  folder_display_name   = "My Cool App Environments"
  parent                = "organizations/123456789012"
  billing_account       = "012345-6789AB-CDEF01"

  # Environments to create (order matters for promotion chain)
  environments = ["dev", "stg", "prod"]

  # GitHub Actions Integration
  github_repository = "my-github-org/my-cool-app-repo"

  # Hub & Spoke WIF configuration
  wif_pool_name = "projects/12345/locations/global/workloadIdentityPools/github-pool"

  # Enable automatic cross-environment artifact promotion
  # This creates standalone IAM resources (not module inputs) to avoid circular deps:
  # - prod (index 2) can read from stg (index 1) and dev (index 0)
  # - stg (index 1) can read from dev (index 0)
  # - dev (index 0) has no cross-project access
  enable_cross_env_artifacts = true
  
  # Region for artifact registries (used when setting up cross-project access)
  region = "us-central1"

  labels = {
    "created-by" = "tofu-module"
    "app"        = "my-cool-app"
  }
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
| `wif_pool_name` | The full resource name of the global Workload Identity Pool from openjusticeok/infrastructure. | `string` | n/a | yes |
| `environments` | A list of environments to create projects for. **Order matters for artifact promotion.** | `list(string)` | `["dev", "stg", "prod"]` | no |
| `labels` | A map of labels to apply to each created project. | `map(string)` | `{}` | no |
| `activate_apis` | A list of APIs to enable on each created project. | `list(string)` | See `variables.tf` | no |
| `tofu_sa_name` | OpenTofu Provisioner service account name for the project. | `string` | `"tofu-provisioner"` | no |
| `tofu_sa_role` | A role to give the OpenTofu Provisioner Service Account for the project. | `string` | `"roles/owner"` | no |
| `enable_cross_env_artifacts` | **(v0.7.0+)** Enable cross-environment artifact promotion. When true, creates **standalone IAM resources** (not module inputs) that grant each environment read access to all lower environments. | `bool` | `false` | no |
| `region` | **(v0.7.0+)** The GCP region for artifact registries (used for cross-project access configuration). | `string` | `"us-central1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| `folder` | The full `google_folder` resource that was created. |
| `projects` | A map of the full `project-factory` module outputs for each environment created. You can access the outputs of a specific project using its environment name as the key (e.g., `module.environment_factory.projects["dev"]`). |
| `project_ids` | A map of the project IDs for each environment, keyed by environment name. |
| `tofu_sa_emails` | A map of the Tofu service account email addresses for each environment, keyed by environment name. |
| `tofu_state_buckets` | A map of the GCS bucket names created for the OpenTofu backend for each environment, keyed by environment name. |
