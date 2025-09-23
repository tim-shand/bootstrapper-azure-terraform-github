# Bootstrap: Github variables for Terraform Remote Backend in Azure.

# Azure ----------------------------------#
variable "azure_tenant_id" {
  description = "The Azure Tenant ID to deploy resources into."
  type        = string
}

variable "platform_subscription_ids" {
  description = "A list of platform subscription IDs for the management group structure."
  type        = list(string)
}

variable "tf_entraid_sp_id" {
  description = "The ID of the Service Principal federated credential used for IaC."
  type        = string
}

# Github ----------------------------------#
variable "github_config" {
  description = "Map of Github configuration settings."
  type = map(string)
}

# Terraform Backend Variables -------------#
variable "tf_backend_rg_name" {
  description = "The name of the Resource Group for Terraform state."
  type = string
}

variable "tf_backend_sa_name" {
  description = "The name of the Storage Account for Terraform state."
  type = string
}

variable "tf_backend_cn_name" {
  description = "The name of the Storage Container for Terraform state."
  type = string
}
