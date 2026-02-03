# Environment Factory Example

This example demonstrates how to use the `environment-factory` module to create a set of environments (e.g., dev, staging, prod) in GCP.

## Prerequisites

This example requires a **global Workload Identity Pool** created in your `openjusticeok/infrastructure` repository. The module follows a "Hub & Spoke" model where WIF pools are centralized.

## Usage

1.  **Update `main.tf`:**
    *   Replace `YOUR_ORGANIZATION_ID` with your GCP organization ID.
    *   Replace `YOUR_BILLING_ACCOUNT_ID` with your GCP billing account ID.
    *   Update `wif_pool_name` with the full resource name from your `openjusticeok/infrastructure` WIF pool output.
    *   Update `github_repository` to point to your GitHub repository.

2.  **Initialize and apply OpenTofu:**

    ```bash
    tofu init
    tofu apply
    ```

## Hub & Spoke WIF Architecture

This example uses the Hub & Spoke model for Workload Identity Federation:
- **Hub**: `openjusticeok/infrastructure` creates ONE global WIF pool for the organization
- **Spoke**: This environment-factory instance creates IAM bindings to that global pool for all environment projects
- **Benefit**: Avoids GCP quota limits and centralizes security policy