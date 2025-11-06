# outputs.tf for the root module

output "dashboard_url" {
  description = "The URL of the deployed pipeline dashboard."
  value       = module.app_service.dashboard_url
}

output "key_vault_uri" {
  description = "The URI of the Key Vault."
  value       = module.key_vault.uri
}

output "storage_account_name" {
  description = "The name of the storage account for artifacts."
  value       = module.storage_account.name
}
