# tofu-modules

OpenTofu modules to provision opinionated infrastructure, including multi-environment GCP project setups.

## Breaking Changes in v0.6.0

**Important:** Version 0.6.0 introduces a breaking change to the Workload Identity Federation (WIF) configuration. The modules now follow a "Hub & Spoke" model where WIF pools and providers are managed centrally in `openjusticeok/infrastructure`, and project modules only create IAM bindings.

**Migration Required:**
- Remove `wif_pool_id` and `wif_provider_id` variables (no longer used)
- Add `wif_pool_name` variable with the full resource name from `openjusticeok/infrastructure`
- Example: `wif_pool_name = "projects/12345/locations/global/workloadIdentityPools/github-pool"`

See the [NEWS.md](NEWS.md) for full details.

## New in v0.7.0 - Cross-Project Artifact Promotion

Version 0.7.0 adds support for promoting container images and GCE disk images between environments (e.g., dev → prod). This enables immutable, traceable deployments without rebuilding artifacts.

**Key Features:**
- **Automatic Waterfall Promotion in `environment-factory`**: Enable `enable_cross_env_artifacts = true` and the module automatically creates IAM bindings that grant each environment read access to all lower environments (prod can read from staging and dev)
  - **Architecture**: Cross-project IAM bindings are created as **standalone resources** after all projects are created, avoiding circular dependency issues
- **Manual Cross-Project Access in `project-factory`**: Use `cross_project_artifact_access` input variable for single-project use cases where you need to grant that project access to external resources

**Which to use?**
- **Creating multiple environments** (dev/stg/prod): Use `environment-factory` with `enable_cross_env_artifacts = true`
- **Single project needing external access**: Use `project-factory` with `cross_project_artifact_access` input

See the [NEWS.md](NEWS.md) for full details and the examples below for usage patterns.

## Modules

### GCP Project Factory

An opinionated wrapper around the [terraform-google-modules/terraform-google-project-factory](https://github.com/terraform-google-modules/terraform-google-project-factory) that provides sensible defaults for OpenJustice OK projects.

#### Features

- **Opinionated Defaults**: Pre-configured with APIs and settings commonly needed by OpenJustice OK
- **Service Account Management**: Automatic creation of a general-purpose service account with configurable roles
- **OpenTofu Backend Support**: Automatic setup of a GCS bucket for OpenTofu state management.
- **Security Best Practices**: Removes default service account, disables auto-network creation
- **Workload Identity Federation**: Hub & Spoke model - consumes global WIF pool from `openjusticeok/infrastructure` and creates IAM bindings for GitHub Actions.
- **Cross-Project Artifact Access** (v0.7.0+): Use `cross_project_artifact_access` input variable to grant this project's provisioner SA read access to other projects' Artifact Registries and GCS buckets. Best for single-project use cases.

#### Hub & Spoke Architecture

This module follows a "Hub & Spoke" identity model to avoid GCP quota limits and centralize security:
- **Hub**: `openjusticeok/infrastructure` creates ONE global WIF pool for the entire organization
- **Spoke**: Each `project-factory` instance creates IAM bindings to that global pool
- **Benefit**: Avoids hitting the 10 pool-per-project quota and centralizes security policy

#### Usage (v0.7.0+)

**Basic Project:**
```hcl
module "project_factory" {
  source = "github.com/openjusticeok/tofu-modules//modules/gcp/project-factory?ref=v0.7.0"

  name            = "my-project"
  billing_account = "012345-6789AB-CDEF01"
  folder_id       = "folders/123456789012"

  labels = {
    environment = "production"
    team        = "infrastructure"
  }

  # Hub & Spoke WIF configuration
  enable_wif        = true
  wif_pool_name     = "projects/12345/locations/global/workloadIdentityPools/github-pool"
  github_repository = "my-owner/my-repo"
}
```

**With Cross-Project Artifact Access (single-project use case):**
```hcl
module "project_factory" {
  source = "github.com/openjusticeok/tofu-modules//modules/gcp/project-factory?ref=v0.7.0"

  name            = "my-project-prod"
  billing_account = "012345-6789AB-CDEF01"
  folder_id       = "folders/123456789012"

  # WIF Configuration
  enable_wif        = true
  wif_pool_name     = "projects/12345/locations/global/workloadIdentityPools/github-pool"
  github_repository = "my-owner/my-app"

  # Cross-project artifact access - for single projects that need to read from external sources
  # Note: For multi-environment setups, use environment-factory with enable_cross_env_artifacts instead
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

### GCP Environment Factory

This module simplifies the creation of multiple, isolated GCP environments (e.g., `dev`, `stg`, `prod`) within a dedicated folder. It uses the `project-factory` module to provision each environment's project, ensuring consistency and applying best practices.

#### Features

- **Multi-Environment Scaffolding**: Creates a specified list of environments, each in its own project.
- **Folder Organization**: Groups all environment projects under a single, new GCP folder.
- **Consistent Project Setup**: Leverages the `project-factory` to ensure each project has the same core configuration, including:
    - Opinionated API enablement
    - Secure service account management with Workload Identity Federation (Hub & Spoke model)
    - OpenTofu backend setup
- **Cross-Environment Artifact Promotion** (v0.7.0+): Enable `enable_cross_env_artifacts = true` and the module automatically creates standalone IAM resources that grant each environment read access to all lower environments. Perfect for CI/CD pipelines that promote artifacts from dev → stg → prod without rebuilding.
- **Customizable**: Allows for custom labels, APIs, and service account roles.

#### Automatic Waterfall Promotion (v0.7.0+)

When `enable_cross_env_artifacts = true`, the module creates **standalone IAM resources** (not module inputs) to establish a promotion chain based on environment order:
- **prod** (index 2): Can read artifacts from **stg** (index 1) and **dev** (index 0)
- **stg** (index 1): Can read artifacts from **dev** (index 0)
- **dev** (index 0): No cross-project access (lowest environment)

**Why standalone resources?** This avoids circular dependency issues that would occur if we passed cross-project references as inputs to the project-factory module.

#### Usage (v0.7.0+)

**Standard Multi-Environment Setup:**
```hcl
module "environment_factory" {
  source = "github.com/openjusticeok/tofu-modules//modules/gcp/environment-factory?ref=v0.7.0"

  name                = "my-app"
  billing_account     = "012345-6789AB-CDEF01"
  parent              = "organizations/123456789012"
  folder_display_name = "My Application Environments"
  github_repository   = "my-owner/my-app"

  # Hub & Spoke: Pass the global WIF pool from openjusticeok/infrastructure
  wif_pool_name       = "projects/12345/locations/global/workloadIdentityPools/github-pool"

  environments = ["dev", "stg", "prod"]

  labels = {
    team = "my-team"
  }
}
```

**With Cross-Environment Artifact Promotion:**
```hcl
module "environment_factory" {
  source = "github.com/openjusticeok/tofu-modules//modules/gcp/environment-factory?ref=v0.7.0"

  name                = "my-app"
  billing_account     = "012345-6789AB-CDEF01"
  parent              = "organizations/123456789012"
  folder_display_name = "My Application Environments"
  github_repository   = "my-owner/my-app"
  wif_pool_name       = "projects/12345/locations/global/workloadIdentityPools/github-pool"

  environments = ["dev", "stg", "prod"]

  # Enable automatic cross-environment artifact promotion
  # This creates standalone IAM resources (not module inputs) to avoid circular deps
  enable_cross_env_artifacts = true
  
  # Region for artifact registries (used when setting up cross-project access)
  region = "us-central1"

  labels = {
    team = "my-team"
  }
}
```

## Examples

- **Project Factory**: See the [project-factory example](examples/gcp/project-factory-example/main.tf) for creating a single, standalone project with optional cross-project access.
- **Environment Factory**: See the [environment-factory example](examples/gcp/environment-factory-example/main.tf) for creating a multi-environment setup with automatic artifact promotion.
