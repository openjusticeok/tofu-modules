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

### GCP Multi-Environment Project Factory

This module provides an opinionated way to set up multiple Google Cloud Platform (GCP) projects for different environments (e.g., `dev`, `staging`, `prod`) within a dedicated GCP folder. It leverages the enhanced `project-factory` module to provision each project with secure Workload Identity Federation (WIF) for GitHub Actions.

#### Features

- **Dedicated Folder Creation**: Automatically creates a new GCP folder to house all environment-specific projects.
- **Multi-Environment Provisioning**: Creates a set of GCP projects based on a configurable map of environments.
- **Leverages Enhanced `project-factory`**: Each project is provisioned using the `project-factory` module, inheriting its features.
- **Branch-Aware CI/CD Integration**: Configures Workload Identity Federation for each project, allowing GitHub Actions to perform branch-specific `plan` and `apply` operations.

#### Usage

```hcl
module "my_application_environments" {
  source = "github.com/openjusticeok/tofu-modules//modules/gcp/multi-env-project-factory"

  parent_id           = "organizations/YOUR_ORGANIZATION_ID"
  folder_display_name = "My Application Environments"
  project_name_prefix = "my-app"
  billing_account     = "YOUR_BILLING_ACCOUNT_ID"
  github_repo         = "openjusticeok/infrastructure"
}
```

## Examples

See the [project-factory example](examples/gcp/project-factory-example/main.tf) and the [multi-env-project-factory example](examples/gcp/multi-env-project-factory-example/main.tf) for complete usage demonstrations.