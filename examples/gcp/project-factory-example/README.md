# Project Factory Example

This example demonstrates how to use the `project-factory` module to create a single GCP project with sensible defaults.

## Prerequisites

This example requires a **global Workload Identity Provider** created in your `openjusticeok/infrastructure` repository. The module follows a "Hub & Spoke" model where WIF pools are centralized.

## Usage

1.  **Update `main.tf`:**
    *   Replace `012345-6789AB-CDEF01` with your GCP billing account ID.
    *   Update `folder_id` to the folder you want to create the project in.
    *   Update `wif_provider_name` with the full resource name from your `openjusticeok/infrastructure` WIF provider output.
    *   Update `github_repository` to point to your GitHub repository.

2.  **Initialize and apply OpenTofu:**

    ```bash
    tofu init
    tofu apply
    ```

## Hub & Spoke WIF Architecture

This example uses the Hub & Spoke model for Workload Identity Federation:
- **Hub**: `openjusticeok/infrastructure` creates ONE global WIF provider for the organization
- **Spoke**: This project-factory instance creates IAM bindings to that global provider
- **Benefit**: Avoids GCP quota limits and centralizes security policy