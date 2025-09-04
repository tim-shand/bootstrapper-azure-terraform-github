output "service_principal_oidc" {
  value = azuread_application_federated_identity_credential.entra_iac_app_cred.application_id
  description = "Service Principal application ID."
}