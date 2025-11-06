# main.tf for the key_vault module

# Creates a random suffix for globally unique resource names.
resource "random_id" "suffix" {
  byte_length = 4
}

# Gets the client configuration from the AzureRM provider.
# This is used to retrieve the tenant ID for Key Vault configuration.
data "azurerm_client_config" "current" {}

# Deploys a Key Vault using the Azure Verified Module.
# This vault will store all secrets for the CI/CD solution.
# RBAC is enabled for granular access control.
module "avm_key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.1"

  name                = "kv-cicd-${random_id.suffix.hex}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"

  # Enable RBAC authorization for modern, secure secret management


  tags = var.tags
}
