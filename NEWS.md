# News

## v0.7.0 (2026-02-06)

### New Features

- **Cross-Project Artifact Promotion Support**: Added support for promoting container images and GCE disk images between projects (e.g., dev → prod).
  
  **For `project-factory`:**
  - Added `cross_project_artifact_access` variable for single-project use cases
  - Added `google_artifact_registry_repository_iam_member.cross_project_reader` resource
  - Added `google_storage_bucket_iam_member.cross_project_bucket_reader` resource
  - Artifact Registry API (`artifactregistry.googleapis.com`) now included in default `activate_apis` list
  
  **For `environment-factory`:**
  - Added `enable_cross_env_artifacts` variable (default: `false`). When enabled, creates standalone IAM resources that grant each environment read access to ALL lower environments (prod can read from stg and dev, stg can read from dev)
  - Added `region` variable for artifact registry location configuration
  - Implements automatic waterfall promotion chain: dev (index 0) → stg (index 1) → prod (index 2)
  - **Architecture Note**: Cross-project IAM bindings are created as standalone resources after all projects are created, avoiding circular dependency issues
  
  **Use Case**: Enable CI/CD pipelines to copy tested artifacts from dev to prod without rebuilding, ensuring immutable, traceable deployments.

### Added

- `project-factory.cross_project_artifact_access` variable - Configure cross-project artifact registry and GCS access (for single-project use)
- `environment-factory.enable_cross_env_artifacts` variable - Enable automatic cross-environment artifact access
- `environment-factory.region` variable - Configure region for artifact registries (default: us-central1)
- `environment-factory` standalone IAM resources for cross-environment access (avoids circular dependencies)
- Artifact Registry API to default activated APIs list

### Fixed

- Resolved circular dependency in `environment-factory` when `enable_cross_env_artifacts = true`. The module now creates cross-project IAM bindings as standalone resources that depend on all projects being created first, rather than passing them as inputs to the project-factory module.

### Documentation

- Updated all READMEs and examples to document new artifact promotion features
- Clarified architecture: `environment-factory` creates standalone IAM resources; `project-factory` accepts `cross_project_artifact_access` as input for single-project use cases
- Added example showing cross-project artifact access configuration

## v0.6.0 (2026-02-03)

### Breaking Changes

- **WIF Refactor - Hub & Spoke Model**: The `project-factory` and `environment-factory` modules no longer create Workload Identity Pools and Providers. Instead, they consume a global pool created by `openjusticeok/infrastructure`.
  
  **Migration Required:**
  - Remove `wif_pool_id` and `wif_provider_id` variables (no longer supported)
  - Add `wif_pool_name` variable with the full resource name from `openjusticeok/infrastructure`
  - Example: `wif_pool_name = "projects/12345/locations/global/workloadIdentityPools/github-pool"`

  **Why:** This prevents hitting GCP quota limits on WIF pools (max 10 per project) and centralizes identity security policy in `openjusticeok/infrastructure`. This is the "Hub & Spoke" architecture.

- **New required variable**: `wif_pool_name` (string) - The full resource name of the global WIF pool

### Added
- Support for Hub & Spoke WIF architecture
- Validation for `wif_pool_name` format
- Demo project in `openjusticeok/infrastructure` to validate the new pattern

### Removed
- `wif_pool_id` variable (no longer creates pools)
- `wif_provider_id` variable (no longer creates providers)
- `google_iam_workload_identity_pool` resource from project-factory
- `google_iam_workload_identity_pool_provider` resource from project-factory

## v0.5.0 (2025-09-11)

### New Modules

- **environment-factory**: Added a new module, `environment-factory`, to simplify the creation of multi-environment GCP setups. This module uses the `project-factory` to provision consistent, isolated projects for environments like `dev`, `stg`, and `prod`.

### Documentation

- Updated the top-level `README.md` to include information about the new `environment-factory` module.
- Created a comprehensive `README.md` for the `environment-factory` module, including features, usage examples, and a full list of inputs and outputs.

## v0.4.0 (2025-09-09)

### Removals
- **multi-env-project-factory**: Removed the `multi-env-project-factory` module.

## v0.3.0 (2025-09-04)

### Fixes
- **project-factory**: Fixed an 'Invalid count argument' error in `project-factory` module's `main.tf` related to conditional IAM binding for the user service account.


## v0.2.0 (2025-08-29)

### Breaking Changes
- **project-factory**: Refactored to be an opinionated wrapper around `terraform-google-modules/terraform-google-project-factory`
- Removed `service_account_display_name` and `service_account_description` variables (no longer supported by upstream module)

### Updates
- **project-factory**: Now leverages the battle-tested terraform-google-modules project factory
- Added opinionated defaults for OpenJustice OK: auto-network creation disabled, default service account removed
- Enhanced security posture with better defaults
- Maintained backward compatibility for most variables and all outputs
- Added comprehensive documentation and examples
- Improved reliability by using the widely-adopted upstream module

### Fixes
- **project-factory**: Corrected the `user_service_account_project_role` variable in the documentation and example, which was previously listed as a list instead of a string.
- **project-factory**: Removed the non-existent `github_actions_conditions` variable from the documentation.
- **project-factory**: Added a warning to the documentation to clarify that the Tofu provisioner service account will become the sole project owner.
- **project-factory**: Clarified the Workload Identity Federation (WIF) behavior in the documentation.
- **project-factory**: Removed the unnecessary `github-actions-workflow.yml` from the example.


## v0.1.0 (2025-08-05)

### Updates
- Initial release of the `project-factory` module for Google Cloud Platform.
- Adopted semantic versioning for better referencing of the modules.
