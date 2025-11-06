# Azure Free Tier CI/CD Infrastructure

This repository contains a complete Infrastructure as Code (IaC) solution for deploying a CI/CD environment on Microsoft Azure at zero cost, leveraging the Azure Free Tier.

## Purpose

The goal of this project is to provide a production-ready, automated, and secure foundation for infrastructure deployment that can be used for portfolio projects, learning, or as a baseline for enterprise-grade CI/CD without incurring any monthly fees.

## Tech Stack

*   **Infrastructure as Code**: Terraform
*   **Cloud Platform**: Microsoft Azure
*   **CI/CD Orchestration**: GitHub Actions
*   **Bootstrap Scripting**: PowerShell

## Key Features & Best Practices

This project was built with industry best practices in mind for sustainability, security, and operational excellence.

### Infrastructure as Code (IaC)

*   **Declarative & Version-Controlled:** The entire Azure environment is defined declaratively using Terraform, stored in Git. This provides a version-controlled, repeatable single source of truth.
*   **Modularity:** The code is broken down into reusable modules (`/terraform/modules`). This improves maintainability, readability, and allows components to be easily reused.
*   **Remote State Management:** Terraform state is stored securely in a dedicated Azure Storage Account with state locking, which is critical for team collaboration.

### CI/CD and DevOps

*   **GitOps Workflow:** All infrastructure changes are managed through pull requests (for review) and merges (for deployment), providing a full audit trail.
*   **Continuous Integration (CI):** On every pull request, a GitHub Actions workflow automatically validates, formats, and generates a `terraform plan` for peer review.
*   **Continuous Deployment (CD):** On every merge to `main`, a GitHub Actions workflow automatically deploys the changes, reducing human error and increasing velocity.

### Security (DevSecOps)

*   **Passwordless Deployments:** The CI/CD pipeline uses **OpenID Connect (OIDC)** to authenticate with Azure, avoiding the need to store long-lived secrets in GitHub.
*   **Centralized Secret Management:** Azure Key Vault is used for all secrets. The infrastructure code is free of hardcoded credentials.
*   **Secure by Default:** The storage account is configured to prefer modern Azure AD authentication, and the CI/CD pipeline is configured to use it, adhering to a more secure operational model.

### Cloud Architecture & Governance

*   **Cost Management (FinOps):** The architecture is designed around the core principle of zero cost by exclusively using Azure Free Tier services.
*   **Policy as Code:** An Azure Policy is deployed via Terraform to programmatically enforce cost constraints, preventing the creation of non-free resources.
*   **Automated Lifecycle Management:** The artifact storage account uses a lifecycle policy to auto-delete old data, preventing storage bloat. The bootstrap and cleanup scripts provide a repeatable, safe way to manage the backend resources.

## Getting Started

1.  **Bootstrap Backend**: Run `./bootstrap.ps1` to create the Azure Storage Account for the Terraform state.
2.  **Configure Secrets**: Add your Azure credentials (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`) to your GitHub repository secrets.
3.  **Deploy**: Push your code to the `main` branch on GitHub to trigger the automated deployment workflow.

## Cleanup

1.  **Destroy Infrastructure**: Run `terraform destroy` from the `terraform` directory to remove the infrastructure deployed by the CI/CD pipeline.
2.  **Destroy Backend**: Run `./bootstrap-cleanup.ps1` to remove the backend resources (resource group and storage account for the Terraform state).
