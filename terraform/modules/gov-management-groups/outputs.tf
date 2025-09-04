output "core_mg_id" {
  value = azurerm_management_group.mg_org_core.id
  description = "The ID of the core management group. Used for assigning RBAC to the SP."
}
