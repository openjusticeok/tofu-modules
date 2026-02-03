# News

## v0.6.0 (2026-02-03)

### Breaking Changes

- **WIF Refactor - Hub & Spoke Model**: The `project-factory` and `environment-factory` modules no longer create Workload Identity Pools and Providers. Instead, they consume a global provider created by `openjusticeok/infrastructure`.
  
  **Migration Required:**
  - Remove `wif_pool_id` and `wif_provider_id` variables (no longer supported)
  - Add `wif_provider_name` variable with the full resource name from `openjusticeok/infrastructure`
  - Example: `wif_provider_name = "projects/12345/locations/global/workloadIdentityPools/github-pool/providers/github-provider"`

  **Why:** This prevents hitting GCP quota limits on WIF pools (max 10 per project) and centralizes identity security policy in `openjusticeok/infrastructure`. This is the "Hub & Spoke" architecture.

- **New required variable**: `wif_provider_name` (string) - The full resource name of the global WIF provider

### Added
- Support for Hub & Spoke WIF architecture
- Validation for `wif_provider_name` format
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
