# Bootstrap: Main Terraform configuration for initializing Azure environment and GitHub repository.

# Module: Build out basic management group structure.
module "bootstrap_management_groups_basic" {
  source = "./modules/gov-management-groups"
  org_prefix = var.org_prefix
  sub_platform_ids = var.sub_platform_ids
  sub_workload_ids = var.sub_workload_ids
}

# Module: Build out Terraform remote backend (state) resources.
module "bootstrap_terraform_backend" {
  source = "./modules/iac-terraform-backend"
  azure_tenant_id = var.azure_tenant_id
  org_prefix = var.org_prefix
  org_project = var.org_project
  org_service = var.org_service
  org_tags = var.org_tags
}

# Module: Create Entra ID resources (group, service principal + federated credential). 
module "bootstrap_entraid_serviceprincipal" {
  source = "./modules/iam-entra-serviceprincipal"
  org_prefix = var.org_prefix
  org_project = var.org_project
  org_service = var.org_service
  github_org = var.github_org
  github_repo = var.github_repo
  github_branch = var.github_branch
  core_mg_id = module.bootstrap_management_groups_basic.core_mg_id
  depends_on = [ module.bootstrap_management_groups_basic ] # Requires the management groups.
}

# Module: Configure Github repository (created if missing) and environment variables.
module "bootstrap_github_repo" {
  source = "./modules/cicd-github-repo"
  sub_platform_id = var.sub_platform_ids[0]
  github_org = var.github_org
  github_repo = var.github_repo
  github_repo_desc = var.github_repo_desc
  azure_tenant_id = var.azure_tenant_id
  sp_oidc_appid = module.bootstrap_entraid_serviceprincipal.service_principal_oidc
  depends_on = [ module.bootstrap_entraid_serviceprincipal ] # Requires the management groups.
}
