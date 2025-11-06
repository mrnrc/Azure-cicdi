# Azure Enterprise CI/CD MVP - Architecture

## 1. Introduction

This document provides a detailed overview of the technical architecture for the Azure Free Tier CI/CD MVP. It expands on the design by detailing the specific configurations of each Azure resource and the interactions between them.

## 2. Detailed Component Architecture

### 2.1. Resource Group

A single Azure Resource Group named `rg-cicd-free-tier` will be created in the `eastus` region. This group will contain all resources, providing a logical boundary for management, policy assignment, and cleanup.

- **Terraform Resource**: `azurerm_resource_group.cicd`
- **Tagging Strategy**: All resources within this group will be tagged with `Environment=Production`, `ManagedBy=Terraform`, and `CostCenter=FreeTier` for governance and tracking.

### 2.2. Storage Infrastructure

#### 2.2.1. Terraform State Storage

To ensure reliable and secure state management, Terraform's state will be stored remotely in a dedicated Azure Storage Account.

- **Resource**: `azurerm` backend block in `backend.tf`.
- **Configuration**:
    - **Resource Group**: `rg-cicd-free-tier` (Note: This is a separate RG for the backend state, as is best practice).
    - **Storage Account**: Name will be `tfstate` plus a random suffix.
    - **Container**: `tfstate`
    - **Key**: `cicd.terraform.tfstate`

#### 2.2.2. Artifact Storage

A general-purpose storage account will be provisioned to store build artifacts.

- **Terraform Module**: `Azure/avm-res-storage-storageaccount/azurerm`
- **Configuration**:
    - **Name**: `stcicdartifacts` plus a random suffix.
    - **SKU**: `Standard_LRS` (Locally-Redundant Storage), which is within the free tier limits.
    - **Lifecycle Policy**: A blob lifecycle policy will be configured to automatically delete artifacts older than 7 days. This is critical for staying within the 5 GB free storage limit.

### 2.3. Security Components

#### 2.3.1. Azure Key Vault

Secrets will be managed by an Azure Key Vault.

- **Terraform Module**: `Azure/avm-res-keyvault-vault/azurerm`
- **Configuration**:
    - **Name**: `kv-cicd-` plus a random suffix.
    - **SKU**: `standard` (The free tier includes standard operations).
    - **Authorization**: Role-Based Access Control (RBAC) will be enabled (`enable_rbac_authorization = true`) for a more granular and manageable permissions model, aligning with modern best practices.

#### 2.3.2. OIDC Authentication

Authentication between GitHub Actions and Azure will be passwordless, using OIDC. This involves creating an Azure AD Application and federated credential that trusts the GitHub repository's actions. The GitHub workflow will use the `azure/login` action with the Client ID, Tenant ID, and Subscription ID to obtain a short-lived access token.

### 2.4. Application Hosting

#### 2.4.1. App Service Plan

A Free Tier App Service Plan will host the pipeline dashboard.

- **Terraform Resource**: `azurerm_service_plan.cicd`
- **Configuration**:
    - **Name**: `asp-cicd-free`
    - **OS**: `Linux`
    - **SKU**: `F1` (The free tier SKU).

#### 2.4.2. Linux Web App

The dashboard itself will be a simple web application.

- **Terraform Resource**: `azurerm_linux_web_app.cicd_dashboard`
- **Configuration**:
    - **Name**: `app-cicd-dashboard-` plus a random suffix.
    - **`always_on`**: Set to `false`, as required by the F1 Free tier.

### 2.5. Governance and Cost Management

#### 2.5.1. Azure Policy for SKU Enforcement

To strictly enforce the zero-cost requirement, a custom Azure Policy will be implemented to prevent the deployment of non-free resources.

- **Terraform Resource**: `azurerm_policy_definition.free_tier_sku` & `azurerm_resource_group_policy_assignment.free_tier_only`
- **Logic**: The policy rule is defined in JSON and denies the creation of:
    1.  `Microsoft.Web/serverfarms` (App Service Plans) where the SKU is not `F1` or `D1` (D1 is for shared tier, also free).
    2.  `Microsoft.Storage/storageAccounts` where the SKU is not `Standard_LRS`.
- **Effect**: `Deny`. Any deployment that violates this rule will fail.

#### 2.5.2. Budget Alerts

An Azure budget will be created with a threshold of $1.00. If any cost is incurred, an alert will be triggered. This acts as a safety net.

- **Implementation**: Via Azure CLI (`az consumption budget create`).

## 3. Code Structure

The Terraform code is structured for clarity and maintainability:

```
terraform/
├── main.tf         # Core resource definitions (RG, App Service, etc.)
├── variables.tf    # Input variables (e.g., subscription_id)
├── outputs.tf      # Outputs (e.g., dashboard URL)
├── backend.tf      # Backend configuration for remote state
└── policies.tf     # (Proposed) Azure Policy definitions
```

This separation of concerns makes the codebase easier to navigate and manage as it grows.
