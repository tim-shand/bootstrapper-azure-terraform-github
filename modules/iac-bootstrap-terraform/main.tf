# Get current AZ session info.
data "azuread_client_config" "current" {} 

# Create Resource Group.
resource "azurerm_resource_group" "tf_rg" {
  name     = "${var.org_naming["prefix"]}-${var.org_naming["project"]}-${var.org_naming["service"]}-rg"
  location = var.location
  tags     = var.org_tags
}
