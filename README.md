# tofu-modules

OpenTofu modules to provision opinionated infrastructure, including multi-environment GCP project setups.

## Breaking Changes in v0.6.0

**Important:** Version 0.6.0 introduces a breaking change to the Workload Identity Federation (WIF) configuration. The modules now follow a "Hub & Spoke" model where WIF pools and providers are managed centrally in `openjusticeok/infrastructure`, and project modules only create IAM bindings.

**Migration Required:**
- Remove `wif_pool_id` and `wif_provider_id` variables (no longer used)
- Add `wif_pool_name` variable with the full resource name from `openjusticeok/infrastructure`
- Example: `wif_pool_name = "projects/12345/locations/global/workloadIdentityPools/github-pool"`

See the [NEWS.md](NEWS.md) for full details.

## Modules

### GCP Project Factory

An opinionated wrapper around the [terraform-google-modules/terraform-google-project-factory](https://github.com/terraform-google-modules/terraform-google-project-factory) that provides sensible defaults for OpenJustice OK projects.

#### Features

- **Opinionated Defaults**: Pre-configured with APIs and settings commonly needed by OpenJustice OK
- **Service Account Management**: Automatic creation of a general-purpose service account with configurable roles
- **OpenTofu Backend Support**: Automatic setup of a GCS bucket for OpenTofu state management.
- **Security Best Practices**: Removes default service account, disables auto-network creation
- **Workload Identity Federation**: Hub & Spoke model - consumes global WIF pool from `openjusticeok/infrastructure` and creates IAM bindings for GitHub Actions.

#### Hub & Spoke Architecture

This module follows a "Hub & Spoke" identity model to avoid GCP quota limits and centralize security:
- **Hub**: `openjusticeok/infrastructure` creates ONE global WIF pool for the entire organization
- **Spoke**: Each `project-factory` instance creates IAM bindings to that global pool
- **Benefit**: Avoids hitting the 10 pool-per-project quota and centralizes security policy

#### Usage (v0.6.0+)

```hcl
module "project_factory" {
  source = "github.com/openjusticeok/tofu-modules//modules/gcp/project-factory?ref=v0.6.0"

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

### GCP Environment Factory

This module simplifies the creation of multiple, isolated GCP environments (e.g., `dev`, `stg`, `prod`) within a dedicated folder. It uses the `project-factory` module to provision each environment's project, ensuring consistency and applying best practices.

#### Features

- **Multi-Environment Scaffolding**: Creates a specified list of environments, each in its own project.
- **Folder Organization**: Groups all environment projects under a single, new GCP folder.
- **Consistent Project Setup**: Leverages the `project-factory` to ensure each project has the same core configuration, including:
    - Opinionated API enablement
    - Secure service account management with Workload Identity Federation (Hub & Spoke model)
    - OpenTofu backend setup
- **Customizable**: Allows for custom labels, APIs, and service account roles.

#### Usage (v0.6.0+)

```hcl
module "environment_factory" {
  source = "github.com/openjusticeok/tofu-modules//modules/gcp/environment-factory?ref=v0.6.0"

  name                = "my-app"
  billing_account     = "012345-6789AB-CDEF01"
  parent              = "organizations/123456789012"
  folder_display_name = "My Application Environments"
  github_repository   = "my-owner/my-repo"

  # Hub & Spoke: Pass the global WIF pool from openjusticeok/infrastructure
  wif_pool_name       = "projects/12345/locations/global/workloadIdentityPools/github-pool"

  environments = ["dev", "stg", "prod"]

  labels = {
    team = "my-team"
  }
}
```

## Examples

- **Project Factory**: See the [project-factory example](examples/gcp/project-factory-example/main.tf) for a demonstration of creating a single, standalone project.
- **Environment Factory**: See the [environment-factory example](examples/gcp/environment-factory-example/main.tf) for a demonstration of creating a multi-environment setup.
