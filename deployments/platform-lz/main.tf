# EXAMPLE: Code for deploying Azure Platform Landing Zone.

# Create Resource Group.
resource "azurerm_resource_group" "example_rg" {
  name     = "${var.naming["prefix"]}-${var.naming["project"]}-${var.naming["environment"]}-${var.naming["service"]}-rg"
  location = var.location
  tags     = var.tags
}
