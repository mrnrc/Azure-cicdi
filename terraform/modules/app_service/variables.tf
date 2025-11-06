# variables.tf for the app_service module

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group where the App Service will be created."
}

variable "location" {
  type        = string
  description = "The Azure region where the App Service will be created."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to the App Service resources."
  default     = {}
}
