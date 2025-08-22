# GitHub Actions CI/CD Setup with WIF

This guide explains how to set up a complete CI/CD pipeline for OpenTofu using the project factory module with Workload Identity Federation (WIF).

## Overview

The project factory module can optionally set up:

1. **OpenTofu Backend**: GCS bucket for state storage and dedicated service account
2. **Workload Identity Federation**: Secure authentication from GitHub Actions to GCP
3. **CI/CD Ready**: GitHub Actions can run `tofu plan` on PRs and `tofu apply` on merge to main

## Step 1: Create Project with WIF Enabled

```hcl
module "my_project" {
  source = "path/to/modules/gcp/project-factory"

  # Basic project configuration
  project_id      = "my-project-12345"
  billing_account = "012345-6789AB-CDEF01"
  folder_id       = "folders/123456789012"
  
  service_account_id = "my-app-sa"
  
  # Enable OpenTofu backend
  enable_tofu_backend_setup = true
  tofu_state_bucket_location = "US-CENTRAL1"
  tofu_provisioner_sa_project_roles = ["roles/owner"]
  
  # Enable WIF for GitHub Actions
  enable_wif        = true
  github_repository = "myorg/my-project-repo"  # Your GitHub repo
  
  labels = {
    environment = "production"
    team        = "infrastructure"
  }
}

# Outputs you'll need for GitHub Actions
output "wif_provider_name" {
  value = module.my_project.wif_provider_name
}

output "github_actions_sa_email" {
  value = module.my_project.github_actions_sa_email
}

output "tofu_state_bucket_name" {
  value = module.my_project.tofu_state_bucket_name
}
```

## Step 2: Apply the Module

Run `tofu apply` to create the project and WIF resources. Note the output values - you'll need them for GitHub Actions configuration.

## Step 3: Configure GitHub Repository

### Set Repository Variables

In your GitHub repository, go to Settings → Secrets and variables → Actions → Variables and add:

| Variable Name | Value | Source |
|---------------|-------|--------|
| `PROJECT_ID` | `my-project-12345` | Your project ID |
| `BILLING_ACCOUNT` | `012345-6789AB-CDEF01` | Your billing account |
| `FOLDER_ID` | `folders/123456789012` | Your folder ID |
| `WIF_PROVIDER_NAME` | `projects/123.../locations/global/workloadIdentityPools/.../providers/...` | Module output `wif_provider_name` |
| `SERVICE_ACCOUNT_EMAIL` | `tofu-provisioner@my-project-12345.iam.gserviceaccount.com` | Module output `github_actions_sa_email` |
| `TOFU_STATE_BUCKET` | `my-project-12345-tfstate` | Module output `tofu_state_bucket_name` |

### Set Repository Permissions

Ensure your repository has the correct permissions:
- Go to Settings → Actions → General
- Under "Workflow permissions", select "Read and write permissions"
- Check "Allow GitHub Actions to create and approve pull requests"

## Step 4: Add GitHub Actions Workflow

Create `.github/workflows/terraform.yml` in your repository (see [example workflow](./github-actions-workflow.yml)).

## Step 5: Create Your Terraform Configuration

Create a `terraform/` directory in your repository with your OpenTofu configuration:

```hcl
# terraform/main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
  
  # Backend will be configured dynamically by GitHub Actions
  backend "gcs" {}
}

provider "google" {
  project = var.project_id
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

# Your resources here...
resource "google_storage_bucket" "example" {
  name     = "${var.project_id}-example-bucket"
  location = "US-CENTRAL1"
}
```

## Step 6: Test the Pipeline

1. **Create a feature branch**: `git checkout -b feature/add-bucket`
2. **Make changes**: Add or modify resources in `terraform/`
3. **Open a PR**: Push your branch and create a pull request
4. **Review the plan**: GitHub Actions will run `tofu plan` and comment the results on your PR
5. **Merge to main**: When merged, GitHub Actions will run `tofu apply`

## Security Considerations

The WIF setup follows security best practices:

- **No service account keys**: GitHub Actions authenticates using short-lived tokens
- **Repository restriction**: Only the specified GitHub repository can impersonate the service account
- **Conditional access**: Access is restricted to main branch and pull requests
- **Principle of least privilege**: The service account has only the permissions needed

## Troubleshooting

### Common Issues

1. **Permission denied**: Verify the service account has the necessary roles
2. **WIF authentication fails**: Check that the GitHub repository name in the module matches exactly
3. **State bucket access denied**: Ensure the service account has `roles/storage.objectAdmin` on the bucket
4. **API not enabled**: The module enables required APIs, but custom resources may need additional APIs

### Debug Commands

```bash
# Check WIF configuration
gcloud iam workload-identity-pools describe github-actions-pool \
  --location="global" \
  --project="my-project-12345"

# Test service account impersonation
gcloud auth print-access-token \
  --impersonate-service-account="tofu-provisioner@my-project-12345.iam.gserviceaccount.com"

# Verify bucket permissions
gsutil iam get gs://my-project-12345-tfstate
```

## Advanced Configuration

### Custom GitHub Actions Conditions

You can customize which GitHub Actions can access the service account:

```hcl
module "my_project" {
  # ... other configuration ...
  
  github_actions_conditions = [
    "assertion.ref == 'refs/heads/main'",
    "assertion.ref == 'refs/heads/develop'", 
    "'pull_request' in assertion.event_name"
  ]
}
```

### Multiple Environments

For multiple environments, create separate projects:

```hcl
module "staging_project" {
  source = "path/to/modules/gcp/project-factory"
  
  project_id        = "my-project-staging-12345"
  github_repository = "myorg/my-project-repo"
  enable_wif        = true
  # ... other configuration ...
}

module "production_project" {
  source = "path/to/modules/gcp/project-factory"
  
  project_id        = "my-project-prod-12345" 
  github_repository = "myorg/my-project-repo"
  enable_wif        = true
  # ... other configuration ...
}
```