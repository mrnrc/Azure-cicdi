# main.tf for the app_service module

# Creates a random suffix for globally unique resource names.
resource "random_id" "suffix" {
  byte_length = 4
}

# Creates a Free Tier (F1) App Service Plan.
# This plan will host the pipeline dashboard web application.
resource "azurerm_service_plan" "cicd" {
  name                = "asp-cicd-free"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "F1"  # Free tier

  tags = var.tags
}

# Creates a Linux Web App to host the pipeline dashboard.
# 'always_on' is set to false, which is a requirement for the Free tier.
resource "azurerm_linux_web_app" "cicd_dashboard" {
  name                = "app-cicd-dashboard-${random_id.suffix.hex}"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.cicd.id

  site_config {
    always_on = false  # Required for Free tier
  }

  tags = var.tags
}
