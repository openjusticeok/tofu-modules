module "my_application_environments" {
  source = "../../../modules/gcp/multi-env-project-factory"

  # Required
  parent_id           = "organizations/YOUR_ORGANIZATION_ID" # Replace with your actual organization ID or parent folder ID
  folder_display_name = "My Application Environments"        # Display name for the new folder
  project_name_prefix = "my-app"                             # e.g., will create my-app-dev, my-app-staging, my-app-prod
  billing_account     = "YOUR_BILLING_ACCOUNT_ID"            # Replace with your actual billing account ID
  github_repo         = "openjusticeok/infrastructure"       # Your infrastructure repository (owner/repo format)

  # Optional: Override default environments or add more
  # environments = {
  #   "dev"     = { branch_name = "dev" },
  #   "staging" = { branch_name = "staging" },
  #   "prod"    = { branch_name = "main" },
  #   "qa"      = { branch_name = "qa" }
  # }

  

  # Optional: Tofu state bucket location (default is "US-CENTRAL1")
  # tofu_state_bucket_location = "us-east1"
}
