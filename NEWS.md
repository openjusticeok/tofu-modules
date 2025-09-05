# News

## v0.3.0 (2025-09-04)

### New Features
- **multi-env-project-factory**: Introduced a new module (`modules/gcp/multi-env-project-factory`) to create multi-environment GCP project setups. This module orchestrates the creation of a parent folder and multiple projects (e.g., dev, staging, prod) within it, leveraging the `project-factory` module.

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
