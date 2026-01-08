# Project Factory Example

This example demonstrates how to use the `project-factory` module to create a single GCP project with sensible defaults.

## Usage

1.  **Update `main.tf`:**
    *   Replace `012345-6789AB-CDEF01` with your GCP billing account ID.
    *   Update `folder_id` to the folder you want to create the project in.
    *   Update `github_repository` to point to your GitHub repository.

2.  **Initialize and apply OpenTofu:**

    ```bash
    tofu init
    tofu apply
    ```