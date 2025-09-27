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
