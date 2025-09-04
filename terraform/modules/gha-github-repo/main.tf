# Create Github Repository (requires auth'd Github CLI session).
resource "github_repository" "gh_repo" {
  name          = var.github_repo
  description   = "Azure: Platform Landing Zone (Basic)"
  visibility    = "private"
}

# Add Federated Identity Credential for GitHub OIDC to Github.
resource "github_actions_secret" "gh_tenant_id" {
  repository      = var.github_repo
  secret_name     = "ARM_TENANT_ID"
  plaintext_value = var.azure_tenant_id
  depends_on = [ github_repository.gh_repo ]
}

resource "github_actions_secret" "gh_subscription_id" {
  repository      = var.github_repo
  secret_name     = "ARM_SUBSCRIPTION_ID"
  plaintext_value = var.sub_platform_id
  depends_on = [ github_repository.gh_repo ]
}

resource "github_actions_secret" "gh_client_id" {
  repository      = var.github_repo
  secret_name     = "ARM_CLIENT_ID"
  plaintext_value = var.sp_oidc_appid # App ID of the Service Principal.
  depends_on = [ github_repository.gh_repo ]
}

resource "github_actions_secret" "gh_use_oidc" {
  repository      = var.github_repo
  secret_name     = "ARM_USE_OIDC"
  plaintext_value = "true"
  depends_on = [ github_repository.gh_repo ]
}
