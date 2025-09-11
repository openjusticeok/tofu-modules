# tofu-modules

OpenTofu modules to provision opinionated infrastructure, including multi-environment GCP project setups.

## Modules

### GCP Project Factory

An opinionated wrapper around the [terraform-google-modules/terraform-google-project-factory](https://github.com/terraform-google-modules/terraform-google-project-factory) that provides sensible defaults for OpenJustice OK projects.

#### Features

- **Opinionated Defaults**: Pre-configured with APIs and settings commonly needed by OpenJustice OK
- **Service Account Management**: Automatic creation of a general-purpose service account with configurable roles
- **OpenTofu Backend Support**: Optional setup of GCS bucket and dedicated service account for OpenTofu state management
- **Security Best Practices**: Removes default service account, disables auto-network creation
- **Battle-Tested**: Built on the widely-used terraform-google-modules project factory
- **Enhanced Workload Identity Federation**: Supports branch-based `plan` and `apply` roles for CI/CD.

#### Key Differences from Upstream

- **Auto-network creation disabled**: Encourages explicit network management
- **Default service account removed**: Better security posture
- **Opinionated API list**: Includes commonly needed APIs for our use cases
- **OpenTofu-specific features**: Built-in support for OpenTofu state backend setup

#### Usage

```hcl
module "project_factory" {
  source = "github.com/openjusticeok/tofu-modules//modules/gcp/project-factory"

  project_id      = "my-project-12345"
  billing_account = "012345-6789AB-CDEF01"
  folder_id       = "folders/123456789012"

  service_account_id = "my-app-sa"
  
  labels = {
    environment = "production"
    team        = "infrastructure"
  }

  enable_tofu_backend_setup = true
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

  project_name      = "my-app"
  billing_account = "012345-6789AB-CDEF01"
  parent_id       = "organizations/123456789012"
  github_repository = "my-owner/my-repo"

  environments = ["dev", "stg", "prod"]

  labels = {
    team = "my-team"
  }
}
```

## Examples

- **Project Factory**: See the [project-factory example](examples/gcp/project-factory-example/main.tf) for a demonstration of creating a single, standalone project.
- **Environment Factory**: See the [environment-factory example](examples/gcp/environment-factory-example/main.tf) for a demonstration of creating a multi-environment setup.