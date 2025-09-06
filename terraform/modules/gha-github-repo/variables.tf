variable "platform_sub_id" {
  description = "The primary subscription ID for the platform landing zone."
  type        = string
}

variable "azure_tenant_id" {
  description = "The Azure Tenant ID to deploy resources into."
  type        = string
}

# variable "github_org" {
#   description = "The Github organization to use for the repository."
#   type        = string
# }

# variable "github_repo" {
#   description = "The Github repository to use for the infrastructure code."
#   type        = string
# }

# variable "github_repo_desc" {
#   description = "The description for the Github repository used for the infrastructure code."
#   type        = string
# }

variable "github_config" {
  description = "Map of Github configuration settings."
  type = map()
}

variable "sp_oidc_appid" {
  description = "The application ID of the Service Principal used for CI/CD."
  type        = string
}