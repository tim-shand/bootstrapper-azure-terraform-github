# Out Terraform Backend resources.check "
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
