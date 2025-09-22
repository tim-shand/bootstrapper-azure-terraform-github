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
