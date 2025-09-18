output "service_principal_oidc" {
  value = azuread_application_federated_identity_credential.entra_iac_app_cred.application_id
  description = "Service Principal application ID."
}

output "service_principal_object_id" {
  value = azuread_application_federated_identity_credential.entra_iac_app_cred.id
  description = "Service Principal object ID."
}