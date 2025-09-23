# Github Resources
output "gh_repo_name" {
  value = module.bootstrap_github_repo.github_repository_name
  description = "The name of the GitHub repository created."
}

# Terraform Service Principal
output "tf_entraid_sp_name" {
  value = module.bootstrap_terraform_backend.tf_entraid_sp_name
  description = "The display name of the Service Principal used for IaC."
}

# Terraform Backend resources
output "tf_backend_rg_name" {
  value = module.bootstrap_terraform_backend.tf_backend_rg_name
  description = "The name of the Resource Group for the Terraform backend."
}

output "tf_backend_sa_name" {
  value = module.bootstrap_terraform_backend.tf_backend_sa_name
  description = "The name of the Storage Account for the Terraform backend."
}

output "tf_backend_cn_name" {
  value = module.bootstrap_terraform_backend.tf_backend_cn_name
  description = "The name of the Container for the Terraform backend."
}
