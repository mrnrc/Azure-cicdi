# variables.tf for the key_vault module

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group where the Key Vault will be created."
}

variable "location" {
  type        = string
  description = "The Azure region where the Key Vault will be created."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to the Key Vault."
  default     = {}
}
