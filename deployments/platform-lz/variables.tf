variable "azure_tenant_id" {
  description = "The Azure Tenant ID to deploy resources into."
  type        = string
}

variable "platform_subscription_id" {
  description = "Platform subscription ID for the management group structure."
  type        = string
}

variable "location" {
  description = "The Azure location to deploy resources into."
  type        = string
  default     = "australiaeast"
}

variable "naming" {
  description = "A map of naming parameters to use with resources."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to apply to resources."
  type        = map(string)
  default     = {}
}
