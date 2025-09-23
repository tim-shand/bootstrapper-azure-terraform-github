output "tf_entraid_sp_name" {
  description = "The display name of the Service Principal used for IaC."
  value       = azuread_application.entra_iac_app.display_name
}

output "tf_entraid_sp_id" {
  description = "The ID of the Service Principal federated credential used for IaC."
  value       = azuread_application_federated_identity_credential.entra_iac_app_cred.application_id
}

output "tf_backend_rg_name" {
  description = "The name of the Resource Group for Terraform state."
  value       = azurerm_resource_group.tf_rg.name
}

output "tf_backend_sa_name" {
  description = "The name of the Storage Account for Terraform state."
  value       = azurerm_storage_account.tf_sa.name
}

output "tf_backend_cn_name" {
  description = "The name of the Storage Container for Terraform state."
  value       = azurerm_storage_container.tf_sc.name
}
