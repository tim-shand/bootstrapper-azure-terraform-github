# Generate a random integer to use for suffix for uniqueness.
resource "random_integer" "rndint" {
  min = 10000
  max = 99999
}

# Dynamically truncate string to a specified maximum length (max 24 chars for SA name).
locals {
  sa_name_max_length = 19 # Random integer suffix will add 5 chars, so max = 19 for base name.
  sa_name_base       = "${var.org_naming["prefix"]}${var.org_naming["project"]}${var.org_naming["service"]}sa${random_integer.rndint.result}"
  sa_name_truncated  = length(local.sa_name_base) > local.sa_name_max_length ? substr(local.sa_name_base, 0, local.sa_name_max_length - 5) : local.sa_name_base
  sa_name_final      = "${local.sa_name_truncated}${random_integer.rndint.result}"
}

# Create Resource Group, Storage Account, Storage Container, and Key Vault.
resource "azurerm_resource_group" "tf_rg" {
  name     = "${var.org_naming["prefix"]}-${var.org_naming["project"]}-${var.org_naming["service"]}-rg"
  location = var.location
  tags     = var.org_tags
}

resource "azurerm_storage_account" "tf_sa" {
  name                     = local.sa_name_final 
  resource_group_name      = azurerm_resource_group.tf_rg.name
  location                 = azurerm_resource_group.tf_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  tags                     = var.org_tags
}

resource "azurerm_storage_container" "tf_sc" {
  name                  = "${var.org_naming["project"]}-${var.org_naming["service"]}-tfstate"
  storage_account_id    = azurerm_storage_account.tf_sa.id
  container_access_type = "private"
}
