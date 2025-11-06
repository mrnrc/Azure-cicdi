# main.tf for the storage_account module

# Creates a random suffix for globally unique resource names.
resource "random_id" "suffix" {
  byte_length = 4
}

# Deploys a storage account using the Azure Verified Module.
# This account will be used to store build artifacts.
# A lifecycle policy is attached to delete artifacts older than 7 days to stay within the 5GB free tier limit.
module "avm_storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.5"

  name                = "stcicdartifacts${random_id.suffix.hex}"
  resource_group_name = var.resource_group_name
  location            = var.location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Lifecycle policy to auto-delete old artifacts
  blob_properties = {
    delete_retention_policy = {
      days = 7
    }
  }

  tags = var.tags
}
