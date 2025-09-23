<#
#======================================#
# Bootstrap: Azure (PowerShell)
#======================================#

# DESCRIPTION:
Bootstrap script to prepare Azure tenant for management via Terraform and Github Actions.
This script performs the following tasks:
- Checks for required local applications (Azure CLI, Terraform, Git, GitHub CLI).
- Checks for local environment variables file and imports configuration.
- Validates Azure CLI authentication and intended Azure tenant ID matches current session.
- Validates Github CLI authentication, confirms provided repo name is available (prompts to delete if exists).
- Creates Azure resources for remote Terraform backend.
- Generates Terraform variable file (TFVARS) from local environment variables.
- Initializes and applies Terraform configuration to create base resources in Azure.
- Adds bootstrap script and Terraform files into the Github repo.

# USAGE:
.\bootstrap-azure-tf-gh.ps1
.\bootstrap-azure-tf-gh.ps1 -destroy
#>

#=============================================#
# VARIABLES
#=============================================#

# General Settings.
param(
    [switch]$destroy # If set, will destroy all resources created by this script.
)
#$ErrorActionPreference = "Stop" # Set the error action preference to stop on errors.
$workingDir = "$((Get-Location).Path)\deployments\bootstrap" # Current working directory.
$envFile = ".\env.psd1" # Local variables file.

# Required applications.
$requiredApps = @(
    [PSCustomObject]@{ Name = "Azure CLI"; Command = "az" }
    [PSCustomObject]@{ Name = "Terraform"; Command = "terraform" }
    [PSCustomObject]@{ Name = "Git"; Command = "git" }
    [PSCustomObject]@{ Name = "GitHub CLI"; Command = "gh" }
)

#=============================================#
# FUNCTIONS
#=============================================#

# Function: Custom logging with terminal colours and timestamp etc.
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("INF", "WRN", "ERR", "SYS")]
        [string]$Level,
        [Parameter(Mandatory=$true)]
        [string]$Message
    )    
    # Set terminal colours based on level parameter.
    switch ($Level){
        "INF" {$textColour = "Green"}
        "WRN" {$textColour = "Yellow"}
        "ERR" {$textColour = "Red"}
        "SYS" {$textColour = "White"}
        default {$textColour = "White"}
    }
    # Write to console.
    if($level -eq "SYS"){
        Write-Host "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) | [$Level] | $message" -ForegroundColor $textColour -NoNewline
    }
    else{
        Write-Host "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) | [$Level] | $message" -ForegroundColor $textColour
    } 
}

# Function: User confirmation prompt, can be re-used for various stages.
function Get-UserConfirm {
    while ($true) {
        $userConfirm = (Read-Host -Prompt "Do you wish to proceed [Y/N]?")
        switch -Regex ($userConfirm.Trim().ToLower()) {
            "^(y|yes)$" {
                return $true
            }
            "^(n|no)$" {
                Write-Log -Level "WRN" -Message " - User declined to proceed."
                return $false
            }
            default {
                Write-Log -Level "WRN" -Message " - Invalid response. Please enter [Y/Yes/N/No]."
            }
        }
    }
}

#=============================================#
# MAIN: Validations & Pre-Checks
#=============================================#

# Clear the console and generate script header message.
Clear-Host
Write-Host -ForegroundColor Cyan "`r`n==========================================================================="
Write-Host -ForegroundColor Magenta "                Bootstrap Script: Azure | Terraform | Github                "
Write-Host -ForegroundColor Cyan "===========================================================================`r`n"

Write-Host -ForegroundColor Cyan "*** Performing Checks & Validations"
# Validate: local environment variables file.
Write-Log -Level "SYS" -Message "Check: Validate local variables file: "
if(Test-Path -Path ".\env.psd1" -PathType Leaf) {
    Try{
        $config = Import-PowerShellDataFile -Path $envFile
        Write-Host "PASS" -ForegroundColor Green
    }
    Catch{
        Write-Host "FAIL" -ForegroundColor Red
        Write-Log -Level "ERR" -Message " - Failed to import local environment variables."
        exit 1
    }
}
else {
    Write-Log -Level "ERR" -Message " - Local environment variables file 'env.psd1' not found. Please create from example file and update values as required."
    exit 1
}

# Validate: Check for required applications.
Write-Log -Level "SYS" -Message "Check: Required applications: "
$appResults = @()
ForEach($app in $requiredApps) {
    Try{
        # Attempt to get the command for each application to test if actually installed.
        Get-Command $app.Command > $null 2>&1
        $appResults += [pscustomobject] @{Name = "$($app.Name)"; Status = "Installed"}
    }
    Catch{
        $appResults += [pscustomobject] @{Name = "$($app.Name)"; Status = "Missing"}
    }
}
if($appResults | Where-Object { $_.Status -eq "Missing" }) {
    Write-Host "FAIL" -ForegroundColor Red
    Write-Log -Level "ERR" -Message " - Required applications check failed. Please install missing applications and try again."
    $appResults | Format-Table -AutoSize
    exit 1
} else{
    Write-Host "PASS" -ForegroundColor Green
}

# Validate: Azure CLI authentication.
# Enable preview extensions, required for renaming subscription.
az config set extension.dynamic_install_allow_preview=true --only-show-errors
Write-Log -Level "SYS" -Message "Check: Validate Azure CLI authenticated session: "
$azSession = az account show -o json | ConvertFrom-JSON 2>$null
if (-not $azSession) {
    Write-Host "FAIL" -ForegroundColor Red
    Write-Log -Level "WRN" -Message " - Not authenticated to Azure CLI. Please run 'az login' and try again."
    exit 1
} else{
    Write-Host "PASS" -ForegroundColor Green
    Write-Log -Level "INF" -Message " - Azure CLI logged in as: $($azSession.user.name) [$($azSession.tenantDefaultDomain)]"
    # Check intended Azure tenant ID matches current session.
    if ($azSession.tenantId -ne $config.azure_tenant_id) {
        Write-Log -Level "ERR" -Message " - Azure CLI tenant ID does not match intended target tenant. Please switch to the correct tenant and try again."
        Write-Log -Level "ERR" -Message "   - Current session tenant ID: $($azSession.tenantId)"
        Write-Log -Level "ERR" -Message "   - Intended target tenant ID: $($config.azure_tenant_id)"
        exit 1
    } else{
        Write-Log -Level "INF" -Message " - Current session tenant ID matches intended target: $($config.azure_tenant_id)"
        if( -not( $($azSession.name) -eq "$($config.naming.prefix)-$($config.naming.project)-$($config.naming.environment)-sub") ){
            if(-not $destroy){
                Try{
                    # Rename default subscription as platform landing zone.
                    Write-Log -Level "INF" -Message " - Setting subscription name to: $($config.naming.prefix)-$($config.naming.project)-$($config.naming.environment)-sub [$($azSession.id)]"
                    $subRename = az account subscription rename --subscription-id "$($config.platform_subscription_ids[0])" `
                    --name "$($config.naming.prefix)-$($config.naming.project)-$($config.naming.environment)-sub" --only-show-errors
                    $subRename | Out-Null
                }
                Catch{
                    Write-Log -Level "WRN" -Message " - Failed to rename subscription. Please check permissions and try again. Skip."
                }
            }
        }
    }
}

# Validate Github CLI authentication.
Write-Log -Level "SYS" -Message "Check: Validate Github CLI authenticated session: "
$ghSession = gh api user 2>$null | ConvertFrom-JSON
if (-not $ghSession) {
    Write-Host "FAIL" -ForegroundColor Red
    Write-Log -Level "WRN" -Message " - Not authenticated to GitHub CLI. Please run 'gh auth login' and try again."
    exit 1
} else{
    Write-Host "PASS" -ForegroundColor Green
    Write-Log -Level "INF" -Message " - Github CLI logged in as: $($ghSession.login) [$($ghSession.html_url)]"
    # Check if provided repo exists, prompt to remove it as it will be re-created by Terraform.
    if(-not $destroy){
        $repoCheck = (gh repo list --json name | ConvertFrom-JSON)
        if ($repoCheck | Where-Object {$_.name -eq "$($config.github_config.repo)"} ) {
            Write-Log -Level "WRN" -Message " - Repository '$($config.github_config.org)/$($config.github_config.repo)' already exists."
            Write-Log -Level "WRN" -Message " - This repository must be removed and re-created to ensure proper configuration."
            Write-Log -Level "WRN" -Message " - If you cannot remove this repository, please provide a different repository name. Overwrite?"
            if(Get-UserConfirm){
                try{
                    gh repo delete "$($config.github_config.org)/$($config.github_config.repo)" --yes
                    Write-Log -Level "INF" -Message " - Repository '$($config.github_config.org)/$($config.github_config.repo)' removed successfully."
                }
                catch{
                    Write-Log -Level "ERR" -Message " - Failed to remove GitHub repository. Please check configuration and try again."
                    exit 1
                }
            }
            else{
                Write-Log -Level "ERR" -Message " - Repository deletion aborted. Please remove manually, or provide a different name and try again."
                exit 1
            }
        }
    }
}

#=============================================#
# MAIN: DESTROY Resources
#=============================================#
if($destroy) {
    Write-Log -Level "WRN" -Message "------------------------------------------------------"
    Write-Log -Level "WRN" -Message "All resources deployed by this script will be removed."
    Write-Log -Level "WRN" -Message "------------------------------------------------------"
    if(Get-UserConfirm){
        Try{
            Write-Host "DESTROY" -ForegroundColor Green
            # Remove Github repository first, as it contains the Github Actions secrets/variables used for Terraform.
            #gh repo delete "$($config.github_config.org)/$($config.github_config.repo)" --yes
            
            Write-Log -Level "INF" -Message " - Initializing Terraform..."
            terraform -chdir="$($workingDir)" init -upgrade
            Write-Log -Level "INF" -Message " - Running Terraform destroy..."
            terraform -chdir="$($workingDir)" destroy -var-file="bootstrap.tfvars" --auto-approve
            Write-Log -Level "INF" -Message " - Resources destroyed successfully."
            exit 0
        }
        Catch{
            Write-Log -Level "ERR" -Message " - Terraform destroy failed. Please check configuration and try again."
            exit 1
        }
    } else{
        Write-Log -Level "WRN" -Message " - Terraform destroy aborted by user."
        exit 1
    }
}

#=============================================#
# MAIN: Generate TFVARS file for Terraform
#=============================================#

# Execute Terraform Deployment.
# Build out Terraform TFVARS file from local env.psd1 file and write to Terraform directory.
$terraformTFVARS = @"
# Azure Settings.
azure_tenant_id = "$($config.azure_tenant_id)" # Target Azure tenant ID.
location = "$($config.location)" # Desired location for resources to be deployed in Azure.
platform_subscription_ids = ["$( $config.platform_subscription_ids -join '","')"] # Platform subscriptions (to be moved to workloads MG).
workload_subscription_ids = ["$( $config.workload_subscription_ids -join '","')"] # Workload subscriptions (to be moved to workloads MG).
core_management_group_id = "$($config.core_management_group_id)" # Desired ID for the top-level management group (under Tenant Root).
core_management_group_display_name = "$($config.core_management_group_display_name)" # Display name for the top-level management group (under Tenant Root).

# Naming Settings (used for resource names).
org_naming = {
  prefix = "$($config.naming.prefix)" # Short name of organization ("abc").
  project = "$($config.naming.project)" # Project name for related resources ("platform", "landingzone").
  service = "$($config.naming.service)" # Service name used in the project ("iac", "mgt", "sec").
  environment = "$($config.naming.environment)" # Environment for resources/project ("dev", "tst", "prd", "alz").
}

# Tags (assigned to all bootstrap resources).
org_tags = {
  Project = "$($config.tags.Project)"
  Environment = "$($config.tags.Environment)" # dev, tst, prd, alz
  Owner = "$($config.tags.Owner)"
  Creator = "$($config.tags.Creator)"
  Created = "$(Get-Date -f 'yyyyMMdd.HHmm')"
}

# GitHub Settings.
github_config = {
  org = "$($config.github_config.org)" # Replace with your GitHub organization name.
  repo = "$($config.github_config.repo)" # Replace with your GitHub repository name.
  repo_desc = "$($config.github_config.repo_desc)" # Description for the GitHub repository.
  branch = "$($config.github_config.branch)" # Replace with your GitHub repository name.
  visibility = "$($config.github_config.visibility)" # Set to "public" or "private" as required.
}
"@
Set-Content -Path "$($workingDir)\bootstrap.tfvars" -Value $terraformTFVARS -Force

#=============================================#
# MAIN: Terrafrom Init & Apply
#=============================================#

# Terraform: Initialize
Write-Log -Level "SYS" -Message "Performing Action: Initialize Terraform configuration... "
if(terraform -chdir="$($workingDir)" init -upgrade){
    Write-Host "PASS" -ForegroundColor Green
} else{
    Write-Host "FAIL" -ForegroundColor Red
    Write-Log -Level "ERR" -Message " - Terraform initialization failed. Please check configuration and try again."
    exit 1
}

# Terraform: Validate
Write-Log -Level "SYS" -Message "Performing Action: Running Terraform validation... "
if(terraform -chdir="$($workingDir)" validate){
    Write-Host "PASS" -ForegroundColor Green
} else{
    Write-Host "FAIL" -ForegroundColor Red
    Write-Log -Level "ERR" -Message " - Terraform validation failed. Please check configuration and try again."
    exit 1
}

# Terraform: Plan
Write-Log -Level "SYS" -Message "Performing Action: Running Terraform plan... "
if(terraform -chdir="$($workingDir)" plan --out=bootstrap.tfplan -var-file="bootstrap.tfvars"){
    Write-Host "PASS" -ForegroundColor Green
    # Show plan output.
    terraform -chdir="$($workingDir)" show "$workingDir\bootstrap.tfplan"
} else{
    Write-Host "FAIL" -ForegroundColor Red
    Write-Log -Level "ERR" -Message " - Terraform plan failed. Please check configuration and try again."
    exit 1
}

# Terraform: Apply
Write-Log -Level "WRN" -Message "Terraform will now deploy resources. This may take several minutes to complete."
if(Get-UserConfirm){
    Write-Log -Level "SYS" -Message "Performing Action: Running Terraform deployment... "
    if(terraform -chdir="$($workingDir)" apply bootstrap.tfplan){
        Write-Host "PASS" -ForegroundColor Green
    } else{
        Write-Host "FAIL" -ForegroundColor Red
        Write-Log -Level "ERR" -Message " - Terraform plan failed. Please check configuration and try again."
        exit 1
    }
}
else{
    Write-Log -Level "WRN" -Message " - Terraform apply aborted by user."
    exit 1
}



#=============================================#
# MAIN: Terrafrom Migrate State
#=============================================#

# Get Github variables from Terraform output.
# $tf_rg = terraform -chdir=deployments/bootstrap output -raw tf_backend_rg_name
Write-Log -Level "SYS" -Message "Retrieving Terraform backend details from output... "
Try{
    $tf_rg = terraform -chdir="$($workingDir)" output -raw tf_backend_rg_name
    $tf_sa = terraform -chdir="$($workingDir)" output -raw tf_backend_sa_name
    $tf_cn = terraform -chdir="$($workingDir)" output -raw tf_backend_cn_name
    Write-Host "PASS" -ForegroundColor Green
    Write-Log -Level "INF" -Message " - Terraform backend details retrieved successfully."
}
Catch{
    Write-Host "FAIL" -ForegroundColor Red
    Write-Log -Level "ERR" -Message " - Failed to get Terraform output values. Please check configuration and try again."
    exit 1
}

# Generate backend config file for state migration.
$backendConfig = @"
    terraform {
      backend "azurerm" {
        resource_group_name  = "$($tf_rg)"
        storage_account_name = "$($tf_sa)"
        container_name       = "$($tf_cn)"
        key                  = "bootstrap.tfstate"
      }
    }
"@
Set-Content -Path "$($workingDir)\backend.tf" -Value $backendConfig -Force

# Terraform: Migrate State
Write-Log -Level "WRN" -Message "Terraform will now migrate state to Azure."
if(Get-UserConfirm){
    terraform -chdir="$($workingDir)" init -migrate-state
    # Cleanup temporary files.
    #Remove-Item -Path "$($workingDir)\backend.tf" -Force
    Remove-Item -Path "$($workingDir)\bootstrap.tfplan" -Force
}
else{
    Write-Log -Level "WRN" -Message " - Terraform apply aborted by user."
    exit 1
}
