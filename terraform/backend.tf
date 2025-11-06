# backend.tf for the root module

# This file is intentionally left with a placeholder backend configuration.
# In a real-world scenario, you would replace this with the actual details
# of your Azure Storage Account for the Terraform state.


terraform {
  backend "azurerm" {
    resource_group_name  = "rg-cicd-free-tier"
    storage_account_name = "tfstatee0818520"
    container_name       = "tfstate"
    key                  = "cicd.terraform.tfstate"
  }
}