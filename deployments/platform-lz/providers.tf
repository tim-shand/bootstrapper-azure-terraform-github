terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~> 4.40.0"
        }
        azuread = {
            source  = "hashicorp/azuread"
            version = "~> 3.5.0"
        }
        random = {
            source  = "hashicorp/random"
            version = "~> 3.7.2"
        }
    }
    required_version = ">= 1.13.0"
}
provider "azurerm" {
  features {}
  subscription_id = var.platform_subscription_id
  tenant_id       = var.azure_tenant_id
}
provider "random" {}
data "azuread_client_config" "current" {} # Get current user session data.