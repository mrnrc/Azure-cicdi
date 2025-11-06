# outputs.tf for the storage_account module

output "name" {
  description = "The name of the storage account."
  value       = module.avm_storage_account.name
}

output "id" {
  description = "The ID of the storage account."
  value       = module.avm_storage_account.resource_id
}