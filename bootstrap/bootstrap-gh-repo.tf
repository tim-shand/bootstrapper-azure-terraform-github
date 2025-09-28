#---------------------------------------------------#
# Github Repository & Variables/Secrets
#---------------------------------------------------#

resource "github_repository" "gh_repo" {
  name          = var.github_config["repo"]
  description   = var.github_config["repo_desc"]
  visibility    = var.github_config["visibility"]
}

# Github: Secrets - Add Federated Identity Credential for OIDC.
resource "github_actions_secret" "gh_tenant_id" {
  repository      = github_repository.gh_repo.name # data.github_repository.gh_repo.name
  secret_name     = "ARM_TENANT_ID"
  plaintext_value = var.azure_tenant_id
}

resource "github_actions_secret" "gh_subscription_id" {
  repository      = github_repository.gh_repo.name # var.github_config["repo"]
  secret_name     = "ARM_SUBSCRIPTION_ID"
  plaintext_value = var.platform_subscription_id # Primary platform subscription ID.
}

resource "github_actions_secret" "gh_client_id" {
  repository      = github_repository.gh_repo.name
  secret_name     = "ARM_CLIENT_ID"
  plaintext_value = azuread_application.entra_iac_app.client_id # Service Principal federated credential ID.
}

resource "github_actions_secret" "gh_use_oidc" {
  repository      = github_repository.gh_repo.name
  secret_name     = "ARM_USE_OIDC" # Must be set to "true" to use OIDC.
  plaintext_value = "true"
}

# Github: Variables - Terraform Backend details.
resource "github_actions_variable" "gh_var_tf_rg" {
  repository       = github_repository.gh_repo.name
  variable_name    = "TF_BACKEND_RG_NAME"
  value            = azurerm_resource_group.tf_rg.name
}

resource "github_actions_variable" "gh_var_tf_sa" {
  repository       = github_repository.gh_repo.name
  variable_name    = "TF_BACKEND_SA_NAME"
  value            = azurerm_storage_account.tf_sa.name
}

resource "github_actions_variable" "gh_var_tf_cn" {
  repository       = github_repository.gh_repo.name
  variable_name    = "TF_BACKEND_CN_NAME"
  value            = azurerm_storage_container.tf_sc.name
}
