variable "platform_sub_id" {
  description = "The primary subscription ID for the platform landing zone."
  type        = string
}

variable "azure_tenant_id" {
  description = "The Azure Tenant ID to deploy resources into."
  type        = string
}

variable "github_config" {
  description = "Map of Github configuration settings."
  type = map(string)
}

variable "sp_oidc_appid" {
  description = "The application ID of the Service Principal used for CI/CD."
  type        = string
}

variable "tf_backend_rg_name" {
  description = "Terraform backend resource group name."
  type        = string
}

variable "tf_backend_sa_name" {
  description = "Terraform backend storage account name."
  type        = string
}

variable "tf_backend_cn_name" {
  description = "Terraform backend container name."
  type        = string
}
