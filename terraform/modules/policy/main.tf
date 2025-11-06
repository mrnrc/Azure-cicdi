# main.tf for the policy module

# Defines a custom Azure Policy to enforce the use of Free Tier SKUs.
# This policy will deny the creation of App Service Plans that are not F1 or D1,
# and Storage Accounts that are not Standard_LRS.
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

# Assigns the custom policy to the specified resource group.
resource "azurerm_resource_group_policy_assignment" "free_tier_only" {
  name                 = "free-tier-enforcement"
  resource_group_id    = var.resource_group_id
  policy_definition_id = azurerm_policy_definition.free_tier_sku.id
}
