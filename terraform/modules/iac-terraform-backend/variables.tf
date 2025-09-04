variable "azure_tenant_id" {
  description = "The Azure Tenant ID to deploy resources into."
  type        = string
}

variable "location" {
  description = "The Azure location to deploy resources into."
  type        = string
  default     = "australiaeast"
}

variable "org_prefix" {
  description = "The prefix to use for resource naming."
  type        = string
}

variable "org_project" {
  description = "The project name to use for resource naming."
  type        = string
}

variable "org_service" {
  description = "The service name to use for resource naming."
  type        = string
}

variable "org_tags" {
  description = "A map of tags to apply to resources."
  type        = map(string)
  default     = {}
}
