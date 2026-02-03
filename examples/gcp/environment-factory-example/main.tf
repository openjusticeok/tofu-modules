module "environment_factory" {
  source = "../../../modules/gcp/environment-factory"

  parent              = "organizations/YOUR_ORGANIZATION_ID"
  folder_display_name = "My Application Environments"
  name                = "my-app" # e.g., will create my-app-dev, my-app-staging, my-app-prod
  billing_account     = "YOUR_BILLING_ACCOUNT_ID"
  github_repository   = "openjusticeok/infrastructure"

  # Hub & Spoke: Pass the global WIF provider from openjusticeok/infrastructure
  wif_provider_name = "projects/12345/locations/global/workloadIdentityPools/github-pool/providers/github-provider"
}
