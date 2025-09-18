# Bootstrap: Variables for Terraform Remote Backend in Azure.

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

variable "service_principal_object_id" {
  description = "The object ID of the Service Principal to assign roles to."
  type        = string
}
