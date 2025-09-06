# Bootstrap: Main Terraform configuration for initializing Azure environment and GitHub repository.

# Module: Build out basic management group structure.
module "bootstrap_management_groups_basic" {
  source = "./modules/gov-management-groups"
  core_management_group_id = var.core_management_group_id
  core_management_group_display_name = var.core_management_group_display_name
  org_naming = var.org_naming
  platform_subscription_ids = var.platform_subscription_ids
  workload_subscription_ids = var.workload_subscription_ids
}

# Module: Build out Terraform remote backend (state) resources.
module "bootstrap_terraform_backend" {
  source = "./modules/iac-terraform-backend"
  azure_tenant_id = var.azure_tenant_id
  org_naming = var.org_naming
  org_tags = var.org_tags
}

# Module: Create Entra ID resources (group, service principal + federated credential). 
module "bootstrap_entraid_serviceprincipal" {
  source = "./modules/idn-terraform-serviceprincipal"
  org_naming = var.org_naming
  github_config = var.github_config
  core_mg_id = module.bootstrap_management_groups_basic.core_mg_id
  depends_on = [ module.bootstrap_management_groups_basic ] # Requires the management groups.
}

# Module: Configure Github repository (created if missing) and environment variables.
module "bootstrap_github_repo" {
  source = "./modules/gha-github-repo"
  azure_tenant_id = var.azure_tenant_id
  sub_platform_id = var.sub_platform_ids[0]
  sp_oidc_appid = module.bootstrap_entraid_serviceprincipal.service_principal_oidc
  github_config = var.github_config
  depends_on = [ module.bootstrap_entraid_serviceprincipal ] # Requires the management groups.
}
