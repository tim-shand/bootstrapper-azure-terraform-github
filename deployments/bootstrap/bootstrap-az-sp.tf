#---------------------------------------------------#
# Service Principal / Federated Credentials
#---------------------------------------------------#

# Create App Registration and Service Principal for Terraform.
resource "azuread_application" "entra_iac_app" {
  display_name     = "${var.naming["prefix"]}-${var.naming["project"]}-${var.naming["service"]}-sp"
  logo_image       = filebase64("./tf-logo.png") # Image file for SP logo.
  owners           = [data.azuread_client_config.current.object_id] # Set current user as owner.
  notes            = "System: Service Principal for IaC (Terraform)." # Descriptive notes on purpose of the SP.
}

# Create Service Principal for the App Registration.
resource "azuread_service_principal" "entra_iac_sp" {
  client_id                    = azuread_application.entra_iac_app.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

# Create federated credential for Service Principal (to be used with GitHub OIDC).
resource "azuread_application_federated_identity_credential" "entra_iac_app_cred" {
  application_id = azuread_application.entra_iac_app.id
  display_name   = "GithubActions-OIDC"
  description    = "Github CI/CD, federated credential."
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_org}/${var.github_config["repo"]}:ref:refs/heads/${var.github_config["branch"]}"
}

# Assign 'Contributor' role for SP at top-level management group.
resource "azurerm_role_assignment" "rbac_mg_sp" {
  scope                = azurerm_management_group.mg_org_core.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.entra_iac_sp.object_id
}