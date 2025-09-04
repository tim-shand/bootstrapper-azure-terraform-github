# Create core management group for the organization.
resource "azurerm_management_group" "mg_org_core" {
  display_name = "Core"
  name         = "${var.org_prefix}-core-mg"
}

# Create child management groups under core management group.
resource "azurerm_management_group" "mg_org_platform" {
  display_name = "Platform"
  name         = "${var.org_prefix}-platform-mg"
  parent_management_group_id = azurerm_management_group.mg_org_core.id
  subscription_ids = var.sub_platform_ids # List of platform subs.
}

resource "azurerm_management_group" "mg_org_workload" {
  display_name = "Workload"
  name         = "${var.org_prefix}-workload-mg"
  parent_management_group_id = azurerm_management_group.mg_org_core.id
  subscription_ids = var.sub_workload_ids # List of workload subs.
}

resource "azurerm_management_group" "mg_org_sandbox" {
  display_name = "Sandbox"
  name         = "${var.org_prefix}-sandbox-mg"
  parent_management_group_id = azurerm_management_group.mg_org_core.id
}
