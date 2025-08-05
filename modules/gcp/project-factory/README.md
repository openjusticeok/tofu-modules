# OpenTofu GCP Project Creation Module

This module creates a new Google Cloud Platform (GCP) project with a set of opinionated configurations, including:
  - Enabling specified APIs.
  - Creating a dedicated general-purpose service account.
  - Assigning specified IAM roles to the general-purpose service account at the project level.
  - Optionally:
    - Creating a GCS bucket configured for use as an OpenTofu state backend.
    - Creating a dedicated "Tofu Provisioner" service account.
    - Granting the Tofu Provisioner SA necessary project-level roles (e.g., Owner) and permissions to the state bucket.
  
## Features
- Creates a new GCP project.
- Associates the project with a billing account.
- Optionally places the project within a specified folder or organization.
- Applies custom labels to the project.Enables a configurable list of GCP APIs.
- Creates a general-purpose service account within the project.
- Grants a configurable list of IAM roles to the general-purpose service account on the project
- Optional Tofu Backend Setup:
  - Creates a GCS bucket with versioning for OpenTofu state.
  - Creates a dedicated service account for OpenTofu provisioning.
  - Grants this provisioner SA appropriate IAM roles on the project and the state bucket

## Prerequisites
- OpenTofu (or Terraform): Version 1.x or later.
- GCP Provider: Configured with credentials that have permissions to:
  - Create projects (roles/resourcemanager.projectCreator).
  - Link projects to billing accounts (roles/billing.user on the billing account).
  - Modify IAM policies on projects (roles/resourcemanager.projectIamAdmin).
  - Enable services/APIs (roles/serviceusage.serviceUsageAdmin).
  - Create service accounts (roles/iam.serviceAccountCreator).
  - Create GCS buckets and set IAM policies (roles/storage.admin).  
  - If creating in a folder, roles/resourcemanager.folderEditor or roles/resourcemanager.projectCreator on the folder.
  - If creating under an organization, roles/resourcemanager.projectCreator on the organization.

## Usage Example

```
module "gcp_project" {
  source = "./path/to/this/module" # Or a Git URL for the module

  project_id                   = "my-app-dev"
  project_name                 = "My App (Development)"
  billing_account              = "012345-6789AB-CDEF01"
  folder_id                    = "folders/123456789012" # Optional

  labels = {
    environment = "development"
    application = "my-app"
  }

  # General-purpose SA for application/workload identity
  service_account_id           = "my-app-workload-sa"
  service_account_project_roles = ["roles/run.invoker", "roles/pubsub.publisher"]

  # --- Enable Tofu Backend Setup ---
  enable_tofu_backend_setup    = true
  tofu_state_bucket_location   = "US-EAST1"
  # tofu_state_bucket_name_suffix = "custom-tfstate" # Optional: overrides default "tfstate"
  tofu_provisioner_sa_id       = "my-app-tofu-deployer"
  tofu_provisioner_sa_project_roles = [
    "roles/owner" # Or a more granular list like ["roles/compute.admin", "roles/storage.admin", ...]
  ]
}

# To get the outputs:
output "new_project_id" {
  value = module.my_new_gcp_project.project_id
}

output "generic_sa_email" {
  value = module.my_new_gcp_project.generic_service_account_email
}

output "tofu_backend_bucket" {
  value = module.my_new_gcp_project.tofu_state_bucket_name
}

output "tofu_provisioner_email" {
  value = module.my_new_gcp_project.tofu_provisioner_sa_email
}
```

### Backend Configuration

Example (backend.tf)
If enable_tofu_backend_setup is true, you can configure your OpenTofu backend in a separate backend.tf file within the project that uses this module (or directly in your main configuration):

```
terraform {
  backend "gcs" {
    bucket  = "my-app-dev-tfstate" # This should match module.my_new_gcp_project.tofu_state_bucket_name
    prefix  = "terraform/state"    # Optional: organize state files within the bucket
  }
}
```

You would typically run tofu init after setting this up. The tofu_provisioner_sa_email can then be used (e.g., via workload identity federation or key impersonation) by your CI/CD system or an analyst to run tofu apply.
