module "environment_factory" {
  source = "../../../modules/gcp/environment-factory"

  parent_id           = "organizations/YOUR_ORGANIZATION_ID"
  folder_display_name = "My Application Environments"
  project_name        = "my-app" # e.g., will create my-app-dev, my-app-staging, my-app-prod
  billing_account     = "YOUR_BILLING_ACCOUNT_ID"
  github_repository   = "openjusticeok/infrastructure"
}