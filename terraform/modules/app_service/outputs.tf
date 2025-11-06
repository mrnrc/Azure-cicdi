# outputs.tf for the app_service module

output "dashboard_url" {
  description = "The URL of the deployed pipeline dashboard."
  value       = "https://${azurerm_linux_web_app.cicd_dashboard.default_hostname}"
}

output "service_plan_id" {
  description = "The ID of the App Service Plan."
  value       = azurerm_service_plan.cicd.id
}
