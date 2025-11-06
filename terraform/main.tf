# main.tf for the root module

# Specifies the required Terraform version and the Azure provider.
terraform {
  required_version = ">= 1.8.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

}

# Configures the Azure Provider.
# The subscription ID is passed as a variable.
provider "azurerm" {
  subscription_id = var.subscription_id

  features {}
}

# Deploys the main resource group for the CI/CD environment.
module "resource_group" {
  source = "./modules/resource_group"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# Deploys the storage account for build artifacts.
module "storage_account" {
  source = "./modules/storage_account"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
}

# Deploys the Key Vault for secret management.
module "key_vault" {
  source = "./modules/key_vault"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
}

# Deploys the App Service and App Service Plan for the dashboard.
module "app_service" {
  source = "./modules/app_service"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
}

# Applies the policy to enforce free-tier resources.
module "policy" {
  source = "./modules/policy"

  resource_group_id = module.resource_group.id
}
