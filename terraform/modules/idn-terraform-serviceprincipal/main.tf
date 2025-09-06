# Create Entra ID group for IaC accounts.

data "azuread_client_config" "current" {} # Get current AZ session info.

# Create App Registration and Service Principal for Terraform.
resource "azuread_application" "entra_iac_app" {
  display_name     = "${var.org_naming["prefix"]}-${var.org_naming["project"]}-${var.org_naming["service"]}-sp"
  logo_image       = filebase64("modules/idn-terraform-serviceprincipal/logo.png")
  owners           = [data.azuread_client_config.current.object_id]
  description      = "System: Service Principal for IaC (Terraform)."
}

resource "azuread_service_principal" "entra_iac_sp" {
  client_id                    = azuread_application.entra_iac_app.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

# Create federated credential for Service Principal.
resource "azuread_application_federated_identity_credential" "entra_iac_app_cred" {
  application_id = azuread_application.entra_iac_app.id
  display_name   = "GithubActions-OIDC"
  description    = "Github CI/CD, federated credential."
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  #subject        = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.github_branch}"
  subject        = "repo:${var.github_config["org"]}/${var.github_config["repo"]}:ref:refs/heads/${var.github_config["branch"]}"
}

# Assign 'Contributor' role for SP at top-level management group.
resource "azurerm_role_assignment" "rbac_mg_iac" {
  scope                = var.core_mg_id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.entra_iac_sp.object_id
}
