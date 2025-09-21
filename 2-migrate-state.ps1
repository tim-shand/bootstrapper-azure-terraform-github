# Generate new Backend file.
$backendConfig = @"
terraform {
    backend "azurerm" {
    resource_group_name  = "my-terraform-state-rg"
    storage_account_name = "myterraformstateaccount" # Globally unique
    container_name       = "terraform-state"
    key                  = "terraform.tfstate"
    }
}
"@
#Set-Content -Path "$workingDir\terraform\bootstrap\backend.tf" -Value $backendConfig -Force