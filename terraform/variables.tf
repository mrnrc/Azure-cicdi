# variables.tf for the root module

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID where resources will be deployed."
  sensitive   = true
}

variable "resource_group_name" {
  type        = string
  description = "The name of the main resource group for CI/CD resources."
  default     = "rg-cicd-free-tier"
}

variable "location" {
  type        = string
  description = "The Azure region for all resources."
  default     = "westus2"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to all resources."
  default = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    CostCenter  = "FreeTier"
    Project     = "AzureCICDI-MVP-One"
  }
}
