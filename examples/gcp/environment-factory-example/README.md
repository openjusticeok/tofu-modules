# Environment Factory Example

This example demonstrates how to use the `environment-factory` module to create a set of environments (e.g., dev, staging, prod) in GCP.

## Usage

1.  **Update `main.tf`:**
    *   Replace `YOUR_ORGANIZATION_ID` with your GCP organization ID.
    *   Replace `YOUR_BILLING_ACCOUNT_ID` with your GCP billing account ID.
    *   Update `github_repository` to point to your GitHub repository.

2.  **Initialize and apply OpenTofu:**

    ```bash
    tofu init
    tofu apply
    ```