# main.tf for the resource_group module

# Creates an Azure Resource Group
# This group will act as a container for all the resources deployed in this solution.
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}
