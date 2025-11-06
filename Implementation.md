# Azure Enterprise CI/CD MVP - Implementation Guide

## 1. Overview

This document provides a step-by-step guide for implementing the Azure Free Tier CI/CD infrastructure. Follow these instructions precisely to provision the architecture using Terraform and GitHub Actions.

## 2. Phase 1: Prerequisites and Setup

### Step 2.1: Set up GitHub Repository

1.  Create a new GitHub repository.
2.  Clone the repository to your local machine.
3.  Create the following directory structure:

    ```
    .
    ├── .github/
    │   └── workflows/
    └── terraform/
    ```

### Step 2.2: Configure Azure OIDC Authentication

Follow the official Azure documentation to create an Azure AD application and a federated credential. This credential should be configured to trust your GitHub repository's `main` branch.

Once created, add the following as secrets to your GitHub repository (`Settings > Secrets and variables > Actions`):

-   `AZURE_CLIENT_ID`: The Client ID of the Azure AD application.
-   `AZURE_TENANT_ID`: Your Azure Tenant ID.
-   `AZURE_SUBSCRIPTION_ID`: Your Azure Subscription ID.

## 3. Phase 2: Infrastructure as Code (Terraform)

Create the following files inside the `terraform/` directory.

### Step 3.1: Create the Terraform Backend

Before creating the Terraform code, you must create the remote backend resources in Azure. This process is automated.

1.  Open a PowerShell terminal.
2.  Run the `bootstrap.ps1` script located in the root of the repository.
3.  This script will log you into Azure and create a dedicated resource group and storage account to be used for the Terraform state.
4.  At the end of the script, it will output a `terraform` block. Copy this block.

### Step 3.2: Configure `backend.tf`

Create a new file at `terraform/backend.tf` and paste the block you copied from the bootstrap script into this file. It will look similar to this:

```hcl
# terraform/backend.tf

terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate..."
    container_name       = "tfstate"
    key                  = "cicd.terraform.tfstate"
  }
}
```

(Note: The `bootstrap-cleanup.ps1` script can be used to tear down these backend resources if needed.)

### Step 3.2: `variables.tf`

```hcl
# terraform/variables.tf

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID where resources will be deployed."
}
```

### Step 3.3: `main.tf`

This file contains the core infrastructure definitions.

```hcl
# terraform/main.tf

terraform {
  required_version = ">= 1.8.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "random_id" "suffix" {
  byte_length = 4
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "cicd" {
  name     = "rg-cicd-free-tier"
  location = "eastus"
  
  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    CostCenter  = "FreeTier"
  }
}

module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.2.7"
  
  name                = "stcicdartifacts${random_id.suffix.hex}"
  resource_group_name = azurerm_resource_group.cicd.name
  location            = azurerm_resource_group.cicd.location
  
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  blob_properties = {
    delete_retention_policy = {
      days = 7
    }
  }
  
  tags = azurerm_resource_group.cicd.tags
}

module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.9.1"
  
  name                = "kv-cicd-${random_id.suffix.hex}"
  resource_group_name = azurerm_resource_group.cicd.name
  location            = azurerm_resource_group.cicd.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  
  sku_name = "standard"
  enable_rbac_authorization = true
  
  tags = azurerm_resource_group.cicd.tags
}

resource "azurerm_service_plan" "cicd" {
  name                = "asp-cicd-free"
  location            = azurerm_resource_group.cicd.location
  resource_group_name = azurerm_resource_group.cicd.name
  os_type             = "Linux"
  sku_name            = "F1"
  
  tags = azurerm_resource_group.cicd.tags
}

resource "azurerm_linux_web_app" "cicd_dashboard" {
  name                = "app-cicd-dashboard-${random_id.suffix.hex}"
  location            = azurerm_resource_group.cicd.location
  resource_group_name = azurerm_resource_group.cicd.name
  service_plan_id     = azurerm_service_plan.cicd.id
  
  site_config {
    always_on = false
  }
  
  tags = azurerm_resource_group.cicd.tags
}
```

### Step 3.4: `policies.tf`

```hcl
# terraform/policies.tf

resource "azurerm_policy_definition" "free_tier_sku" {
  name         = "enforce-free-tier-skus"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Enforce Free Tier SKUs Only"
  
  policy_rule = jsonencode({
    if = {
      anyOf = [
        {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.Web/serverfarms"
            },
            {
              field  = "Microsoft.Web/serverfarms/sku.name"
              notIn  = ["F1", "D1"]
            }
          ]
        },
        {
          allOf = [
            {
              field  = "type"
              equals = "Microsoft.Storage/storageAccounts"
            },
            {
              field  = "Microsoft.Storage/storageAccounts/sku.name"
              notLike = "Standard_LRS"
            }
          ]
        }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}

resource "azurerm_resource_group_policy_assignment" "free_tier_only" {
  name                 = "free-tier-enforcement"
  resource_group_id    = azurerm_resource_group.cicd.id
  policy_definition_id = azurerm_policy_definition.free_tier_sku.id
}
```

## 4. Phase 3: CI/CD Pipeline (GitHub Actions)

Create the following workflow files in the `.github/workflows/` directory.

### Step 4.1: `terraform-plan.yml`

```yaml
# .github/workflows/terraform-plan.yml
name: Terraform Plan

on:
  pull_request:
    branches: [main]
    paths:
      - 'terraform/**'
      - '.github/workflows/terraform-*.yml'

permissions:
  id-token: write
  contents: read
  pull-requests: write

jobs:
  terraform-plan:
    runs-on: ubuntu-latest
    env:
      ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
        
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.8.0
          
      - name: Azure Login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          
      - name: Terraform Init
        working-directory: ./terraform
        run: terraform init
        
      - name: Terraform Format Check
        working-directory: ./terraform
        run: terraform fmt -check
        
      - name: Terraform Validate
        working-directory: ./terraform
        run: terraform validate
        
      - name: Terraform Plan
        working-directory: ./terraform
        run: terraform plan -out=tfplan -input=false -var="subscription_id=${{ secrets.AZURE_SUBSCRIPTION_ID }}"
        
      - name: Upload Plan Artifact
        uses: actions/upload-artifact@v4
        with:
          name: tfplan
          path: terraform/tfplan
          retention-days: 5
```

### Step 4.2: `terraform-apply.yml`

```yaml
# .github/workflows/terraform-apply.yml
name: Terraform Apply

on:
  push:
    branches: [main]
    paths:
      - 'terraform/**'

permissions:
  id-token: write
  contents: read

jobs:
  terraform-apply:
    runs-on: ubuntu-latest
    environment: production
    env:
      ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
        
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.8.0
          
      - name: Azure Login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          
      - name: Terraform Init
        working-directory: ./terraform
        run: terraform init
        
      - name: Terraform Apply
        working-directory: ./terraform
        run: terraform apply -auto-approve -var="subscription_id=${{ secrets.AZURE_SUBSCRIPTION_ID }}"
```

## 5. Phase 4: Execution

1.  Commit all the files created above to a new branch.
2.  Push the branch to your GitHub repository.
3.  Create a pull request to the `main` branch. This will trigger the `terraform-plan` workflow.
4.  Review the plan output in the GitHub Actions logs.
5.  Merge the pull request. This will trigger the `terraform-apply` workflow, which will provision the Azure resources.
