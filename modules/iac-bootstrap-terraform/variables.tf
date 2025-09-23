# Bootstrap: Variables for Terraform Remote Backend in Azure.

# General ----------------------------------#
variable "azure_tenant_id" {
  description = "The Azure Tenant ID to deploy resources into."
  type        = string
}

variable "location" {
  description = "The Azure location to deploy resources into."
  type        = string
  default     = "australiaeast"
}

variable "org_naming" {
  description = "A map of naming values to apply to resources."
  type        = map(string)
  default     = {}
}

variable "org_tags" {
  description = "A map of tags to apply to resources."
  type        = map(string)
  default     = {}
}

# Management Group ----------------------------------#
variable "core_mg_id" {
  description = "The ID of the core management group. Used for assigning RBAC."
  type        = string
}

# Github ----------------------------------#
variable "github_config" {
  description = "Map of Github configuration settings."
  type = map(string)
}