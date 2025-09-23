# Bootstrap: Main Terraform configuration for initializing Azure environment and GitHub repository.

# Module: Build out basic management group structure.
module "bootstrap_management_groups" {
  source                              = "../../modules/gov-management-groups"
  org_naming                         = var.org_naming
  core_management_group_id           = var.core_management_group_id
  core_management_group_display_name = var.core_management_group_display_name
  platform_subscription_ids          = var.platform_subscription_ids
  workload_subscription_ids          = var.workload_subscription_ids
}

# Module: Build out Terraform remote backend (state) resources.
module "bootstrap_terraform_backend" {
  source                    = "../../modules/iac-bootstrap-terraform"
  azure_tenant_id           = var.azure_tenant_id
  location                  = var.location
  org_naming                = var.org_naming
  org_tags                  = var.org_tags
  core_mg_id                = module.bootstrap_management_groups.core_mg_id
  github_config             = var.github_config
  depends_on                = [module.bootstrap_management_groups]
}

# Module: Github repository and CI/CD setup.
module "bootstrap_github_repo" {
  source                    = "../../modules/git-github-repo"
  github_config             = var.github_config
  azure_tenant_id           = var.azure_tenant_id
  platform_subscription_ids = var.platform_subscription_ids
  tf_entraid_sp_id          = module.bootstrap_terraform_backend.tf_entraid_sp_id
  tf_backend_rg_name        = module.bootstrap_terraform_backend.tf_backend_rg_name
  tf_backend_sa_name        = module.bootstrap_terraform_backend.tf_backend_sa_name
  tf_backend_cn_name        = module.bootstrap_terraform_backend.tf_backend_cn_name
  depends_on                = [module.bootstrap_management_groups]
}
