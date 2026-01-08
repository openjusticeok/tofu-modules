# tofu-modules

OpenTofu modules to provision opinionated infrastructure, including multi-environment GCP project setups.

## Modules

### GCP Project Factory

An opinionated wrapper around the [terraform-google-modules/terraform-google-project-factory](https://github.com/terraform-google-modules/terraform-google-project-factory) that provides sensible defaults for OpenJustice OK projects.

#### Features

- **Opinionated Defaults**: Pre-configured with APIs and settings commonly needed by OpenJustice OK
- **Service Account Management**: Automatic creation of a general-purpose service account with configurable roles
- **OpenTofu Backend Support**: Automatic setup of a GCS bucket for OpenTofu state management.
- **Security Best Practices**: Removes default service account, disables auto-network creation
- **Workload Identity Federation**: Simplified setup for Workload Identity Federation to allow GitHub Actions to impersonate service accounts.

#### Usage

```hcl
module "project_factory" {
  source = "github.com/openjusticeok/tofu-modules//modules/gcp/project-factory"

  name            = "my-project"
  billing_account = "012345-6789AB-CDEF01"
  folder_id       = "folders/123456789012"

  labels = {
    environment = "production"
    team        = "infrastructure"
  }

  enable_wif        = true
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
    - Secure service account management with Workload Identity Federation
    - OpenTofu backend setup
- **Customizable**: Allows for custom labels, APIs, and service account roles.

#### Usage

```hcl
module "environment_factory" {
  source = "github.com/openjusticeok/tofu-modules//modules/gcp/environment-factory"

  name                = "my-app"
  billing_account     = "012345-6789AB-CDEF01"
  parent              = "organizations/123456789012"
  folder_display_name = "My Application Environments"
  github_repository   = "my-owner/my-repo"

  environments = ["dev", "stg", "prod"]

  labels = {
    team = "my-team"
  }
}
```

## Examples

- **Project Factory**: See the [project-factory example](examples/gcp/project-factory-example/main.tf) for a demonstration of creating a single, standalone project.
- **Environment Factory**: See the [environment-factory example](examples/gcp/environment-factory-example/main.tf) for a demonstration of creating a multi-environment setup.
