# Github Resources
# output "gh_repo_name" {
#   value = module.bootstrap_github_repo.github_repository_name
#   description = "The name of the GitHub repository created."
# }

# Terraform Service Principal

output "tf_entraid_sp_name" {
  description = "The display name of the Service Principal used for IaC."
  value       = azuread_application.entra_iac_app.display_name
}

output "tf_entraid_sp_appid" {
  description = "The Application ID of the Service Principal used for IaC."
  value       = azuread_application.entra_iac_app.client_id
}

# Terraform Backend resources
output "tf_backend_rg_name" {
  description = "The name of the Resource Group for the Terraform backend."
  value = azurerm_resource_group.tf_rg.name
}

output "tf_backend_sa_name" {
  description = "The name of the Storage Account for the Terraform backend."
  value = azurerm_storage_account.tf_sa.name
}

output "tf_backend_cn_name" {
  description = "The name of the Container for the Terraform backend."
  value = azurerm_storage_container.tf_sc.name
}

# GitHub
output "github_repository_name" {
  description       = "GitHub repository name."
  value             = github_repository.gh_repo.name
  sensitive         = false
}
