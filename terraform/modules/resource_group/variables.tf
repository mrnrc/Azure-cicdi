# variables.tf for the resource_group module

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group."
}

variable "location" {
  type        = string
  description = "The Azure region where the resources will be created."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to the resource group."
  default     = {}
}
