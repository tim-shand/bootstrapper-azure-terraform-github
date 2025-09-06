# Bootstrap: Variables for Azure Management Groups.

variable "core_management_group_id" {
  description = "Desired ID for the top-level management group (under Tenant Root)."
  type        = string
}

variable "core_management_group_display_name" {
  description = "Display name for the top-level management group (under Tenant Root)"
  type        = string
}

variable "platform_subscription_ids" {
  description = "A list of platform subscription IDs for the management group structure."
  type        = list(string)
}

variable "workload_subscription_ids" {
  description = "A list of workload subscription IDs for the management group structure."
  type        = list(string)
}

variable "org_naming" {
  description = "A map of naming values to apply to resources."
  type        = map(string)
  default     = {}
}