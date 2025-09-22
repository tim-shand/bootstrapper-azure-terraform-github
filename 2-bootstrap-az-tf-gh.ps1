<#
#======================================#
# Bootstrap: Azure (PowerShell)
#======================================#

# DESCRIPTION:
Bootstrap script to prepare Azure tenant for management via Terraform and Github Actions.
This script performs the following tasks:
- Checks for local environment variables file and imports configuration.
- Checks for required local applications (Azure CLI, Terraform, Git, GitHub CLI).
- Validates Azure CLI authentication and intended Azure tenant ID matches current session.
- Validates Github CLI authentication, confirms provided repo name is available (prompts to create if missing).
- Create Service Principal for Terraform with role assignments.
- Creates Azure resources for remote Terraform backend (Resource Group, Storage Account, Blob Container).

- Generates Terraform variable file (TFVARS) from local environment variables.
- Initializes and applies Terraform configuration to create base resources Azure.
- Adds bootstrap script and Terraform files into the Github repo.

# USAGE:
.\bootstrap-az-tf-gh.ps1
.\bootstrap-az-tf-gh.ps1 -destroy
#>

#=============================================#
# VARIABLES
#=============================================#

# General Settings.
param(
    [switch]$destroy # If set, will destroy all resources created by this script.
)
$ErrorActionPreference = "Stop" # Set the error action preference to stop on errors.
$workingDir = (Get-Location).Path # Current working directory.
$envFile = "$workingDir\env.psd1" # Local variables file.

# Required applications.
$requiredApps = @(
    [PSCustomObject]@{ Name = "Azure CLI"; Command = "az" }
    [PSCustomObject]@{ Name = "Terraform"; Command = "terraform" }
    [PSCustomObject]@{ Name = "Git"; Command = "git" }
    [PSCustomObject]@{ Name = "GitHub CLI"; Command = "gh" }
    #[PSCustomObject]@{ Name = "Fake App"; Command = "ghfghbsdhgs" }
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
        Write-Log -Level "ERR" -Message " - Azure CLI tenant ID does not match intended target. Please switch to the correct tenant and try again."
        Write-Log -Level "ERR" -Message "   - Current session tenant ID: $($azSession.tenantId) != $($config.azure_tenant_id)"
        exit 1
    } else{
        Write-Log -Level "INF" -Message " - Current session tenant ID matches intended target: $($config.azure_tenant_id)"
        if( -not( $($azSession.name) -eq "$($config.naming.prefix)-$($config.naming.project)-$($config.naming.environment)-sub") ){
            Try{
                # Rename default subscription as platform landing zone.
                Write-Log -Level "INF" -Message " - Setting subscription name to: $($config.naming.prefix)-$($config.naming.project)-$($config.naming.environment)-sub [$($azSession.id)]"
                #$subRename = az account subscription rename --subscription-id "$($config.platform_subscription_ids[0])" `
                #--name "$($config.naming.prefix)-$($config.naming.project)-$($config.naming.environment)-sub" --only-show-errors
                $subRename | Out-Null
            }
            Catch{
                Write-Log -Level "WRN" -Message " - Failed to rename subscription. Please check permissions and try again. Skip."
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
} 
else{
    Write-Host "PASS" -ForegroundColor Green
    Write-Log -Level "INF" -Message " - Github CLI logged in as: $($ghSession.login) [$($ghSession.html_url)]"
    # Check for existing repository with provided name.    
    $repoCheck = (gh repo list --json name | ConvertFrom-JSON)
    if ($repoCheck | Where-Object {$_.name -eq "$($config.github_config.repo)"} ) {
        Write-Log -Level "INF" -Message " - Provided repository '$($config.github_config.org)/$($config.github_config.repo)' found."
    }
    else{
        Write-Log -Level "WRN" -Message " - Provided repository '$($config.github_config.org)/$($config.github_config.repo)' not found. Create now?"
        if(Get-UserConfirm){
            try{
                gh repo create "$($config.github_config.org)/$($config.github_config.repo)" --$($config.github_config.visibility) `
                --description "$($config.github_config.repo_desc)" 2>$null
                Write-Log -Level "INF" -Message " - Repository '$($config.github_config.org)/$($config.github_config.repo)' created successfully."
            }
            catch{
                Write-Log -Level "ERR" -Message " - Failed to create GitHub repository. Please check configuration and try again."
                exit 1
            }
        }
        else{
            Write-Log -Level "ERR" -Message " - Repository creation aborted. Please create manually, or provide a different name and try again."
            exit 1
        }
    }
}

#=============================================#
# MAIN: Deploy Resources
#=============================================#

# Set names for resources to be created.
$rnd = Get-Random -Minimum 10000000 -Maximum 99999999 # Random number to ensure storage account name is unique.
$servicePrincipalName = "$($config.naming.prefix)-$($config.naming.project)-$($config.naming.service)-sp"
$resourceGroupName = ("$($config.naming.prefix)-$($config.naming.project)-$($config.naming.service)-rg").ToLower()
$storageAccountNameInit = ($config.naming.prefix + $config.naming.project + $config.naming.service + "sa").ToLower()
$storageAccountName = $storageAccountNameInit.Substring(0, [System.Math]::Min($storageAccountNameInit.Length, 16))+$rnd
$containerName = "tfstate"

# Create: Service Principal
Write-Log -Level "SYS" -Message "Create: Service Principal: "
Try{
    $sp = az ad sp create-for-rbac --name "$servicePrincipalName" --role "Contributor" --scopes "/subscriptions/$($config.platform_subscription_ids[0])" --sdk-auth
    Write-Host "PASS" -ForegroundColor Green
}
Catch{
    Write-Host "FAIL" -ForegroundColor Red
    Write-Log -Level "ERR" -Message " - Failed to create service principal. Please check configuration and try again."
    exit 1
}
az ad sp create-for-rbac --name "$servicePrincipalName" --role "Contributor" --scopes "/subscriptions/YOUR_SUBSCRIPTION_ID"

# Create: Resource Group
Write-Host -ForegroundColor Cyan "`r`n*** Deploying Azure Resources"
Write-Log -Level "SYS" -Message "Create: Resource Group: "
Try{
    $rg = az group create --name "$resourceGroupName" --location "$($config.location)"
    Write-Host "PASS" -ForegroundColor Green
}
Catch{
    Write-Host "FAIL" -ForegroundColor Red
    Write-Log -Level "ERR" -Message " - Failed to create resource group. Please check configuration and try again."
    exit 1
}

# Create: Storage Account
Write-Log -Level "SYS" -Message "Create: Storage Account: "
Try{
    $sa = az storage account create --name "$storageAccountName" --resource-group "$resourceGroupName" `
    --location "$($config.location)" --sku Standard_LRS --auth-mode login --kind StorageV2 
    Write-Host "PASS" -ForegroundColor Green
}
Catch{
    Write-Host "FAIL" -ForegroundColor Red
    Write-Log -Level "ERR" -Message " - Failed to create storage account. Please check configuration and try again."
    exit 1
}

# Create: Blob Container
Write-Log -Level "SYS" -Message "Create: Storage Container: "
Try{
    $ctn = az storage container create --name "$containerName" --account-name "$storageAccountName" --fail-on-exist
    Write-Host "PASS" -ForegroundColor Green
}
Catch{
    Write-Host "FAIL" -ForegroundColor Red
    Write-Log -Level "ERR" -Message " - Failed to create storage container. Please check configuration and try again."
    exit 1
}
