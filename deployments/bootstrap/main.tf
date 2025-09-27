#---------------------------------------------------#
# General / Preparation
#---------------------------------------------------#

# Generate a random integer to use for suffix for uniqueness.
resource "random_integer" "rndint" {
  min = 10000
  max = 99999
}

#---------------------------------------------------#
# Management Groups
#---------------------------------------------------#

# Create core top-level management group for the organization.
resource "azurerm_management_group" "mg_org_core" {
  display_name = var.core_management_group_display_name
  name         = "${var.naming["prefix"]}-${var.core_management_group_id}"
}

# Create child management groups under core management group.
resource "azurerm_management_group" "mg_org_platform" {
  display_name = "Platform"
  name         = "${var.naming["prefix"]}-platform-mg"
  parent_management_group_id = azurerm_management_group.mg_org_core.id
  subscription_ids = [var.platform_subscription_id] # List of platform subs.
}
resource "azurerm_management_group" "mg_org_workload" {
  display_name = "Workload"
  name         = "${var.naming["prefix"]}-workload-mg"
  parent_management_group_id = azurerm_management_group.mg_org_core.id
}
resource "azurerm_management_group" "mg_org_sandbox" {
  display_name = "Sandbox"
  name         = "${var.naming["prefix"]}-sandbox-mg"
  parent_management_group_id = azurerm_management_group.mg_org_core.id
}
resource "azurerm_management_group" "mg_org_decom" {
  display_name = "Decommissioned"
  name         = "${var.naming["prefix"]}-decom-mg"
  parent_management_group_id = azurerm_management_group.mg_org_core.id
}

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

#---------------------------------------------------#
# Terraform Backend Resources
#---------------------------------------------------#

# Create Resource Group.
resource "azurerm_resource_group" "tf_rg" {
  name     = "${var.naming["prefix"]}-${var.naming["project"]}-${var.naming["environment"]}-${var.naming["service"]}-rg"
  location = var.location
  tags     = var.tags
}

# Dynamically truncate string to a specified maximum length (max 24 chars for SA name).
locals {
  sa_name_max_length = 19 # Random integer suffix will add 5 chars, so max = 19 for base name.
  sa_name_base       = "${var.naming["prefix"]}${var.naming["project"]}${var.naming["service"]}sa${random_integer.rndint.result}"
  sa_name_truncated  = length(local.sa_name_base) > local.sa_name_max_length ? substr(local.sa_name_base, 0, local.sa_name_max_length - 5) : local.sa_name_base
  sa_name_final      = "${local.sa_name_truncated}${random_integer.rndint.result}"
}

# Storage Account.
resource "azurerm_storage_account" "tf_sa" {
  name                     = local.sa_name_final 
  resource_group_name      = azurerm_resource_group.tf_rg.name
  location                 = azurerm_resource_group.tf_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  tags                     = var.tags
}

# Storage Container.
resource "azurerm_storage_container" "tf_sc" {
  name                  = "${var.naming["project"]}-${var.naming["service"]}-tfstate"
  storage_account_id    = azurerm_storage_account.tf_sa.id
  container_access_type = "private"
}

# Assign 'Storage Data Contributor' role for current user.
resource "azurerm_role_assignment" "rbac_sa_cu1" {
  scope                = azurerm_storage_account.tf_sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azuread_client_config.current.object_id
}

# Assign 'Storage Data Contributor' role for SP.
resource "azurerm_role_assignment" "rbac_sa_sp1" {
  scope                = azurerm_storage_account.tf_sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.entra_iac_sp.object_id
}