# Azure Settings.

variable "azure_tenant_id" {
  description = "The Azure Tenant ID to deploy resources into."
  type        = string
}

variable "location" {
  description = "The Azure location to deploy resources into."
  type        = string
  default     = "australiaeast"
}

variable "platform_subscription_ids" {
  description = "A list of platform subscription IDs for the management group structure ['a', 'b', 'c']."
  type        = list(string)
}

variable "workload_subscription_ids" {
  description = "A list of workload subscription IDs for the management group structure ['a', 'b', 'c']."
  type        = list(string)
  nullable    = true # Allows to explicitly set this variable to null.
}

variable "core_management_group_id" {
  description = "Desired ID of the top-level management group (under Tenant Root)."
  type        = string
}

variable "core_management_group_display_name" {
  description = "Desired display name of the top-level management group (under Tenant Root)."
  type        = string
}

variable "org_naming" {
  description = "A map of naming parameters to use with resources."
  type        = map(string)
  default     = {}
}

variable "org_tags" {
  description = "A map of tags to apply to resources."
  type        = map(string)
  default     = {}
}

variable "github_config" {
  description = "A map of Github settings."
  type        = map(string)
  default     = {}
}
