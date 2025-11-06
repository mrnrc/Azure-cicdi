# outputs.tf for the key_vault module

output "name" {
  description = "The name of the Key Vault."
  value       = module.avm_key_vault.name
}

output "id" {
  description = "The ID of the Key Vault."
  value       = module.avm_key_vault.resource_id
}

output "uri" {
  description = "The URI of the Key Vault."
  value       = module.avm_key_vault.uri
}