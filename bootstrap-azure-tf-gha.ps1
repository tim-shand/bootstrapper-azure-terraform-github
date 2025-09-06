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
 - Validates Github CLI authentication, confirms provided repo is accessible (prompts to create if not exists).
 - Generates Terraform variables file (TFVARS).
 - Uses Terraform template files to creates Azure resources for remote Terraform backend.
 - Migrates temporary local Terraform backend used during bootstrap process into newly created Azure resources.
 - Adds bootstrap script and Terraform files into the Github repo.

# USAGE:
.\scripts\bootstrap\bootstrap-azure-tf-gh.ps1
#>

#=============================================#
# VARIABLES
#=============================================#

# General Settings.
$ErrorActionPreference = "Stop" # Set the error action preference to stop on errors.
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
    Write-Host "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) | [$Level] | $message" -ForegroundColor $textColour
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

# Function: Check for required applications.
function Get-RequiredApps {
    $appResults = @()
    ForEach($app in $requiredApps) {
        Try{
            # Attempt to get the command for each application to test if actually installed.
            Get-Command $app.Command > $null 2>&1
            Write-Log -Level "INF" -Message " - $($app.Name) is installed."
            $appResults += [pscustomobject] @{Name = "$($app.Name)"; Status = "Installed"}
        }
        Catch{
            Write-Log -Level "WRN" -Message " - $($app.Name) is missing. Please install and try again."
            $appResults += [pscustomobject] @{Name = "$($app.Name)"; Status = "Missing"}
        }
    }
    return $appResults
}

#=============================================#
# MAIN SCRIPT
#=============================================#

# Clear the console and generate script header message.
Clear-Host
Write-Host -ForegroundColor Cyan "`r`n=============== Bootstrap Script: Azure | Terraform | Github ===============`r`n"
Write-Host -ForegroundColor Cyan "NOTE: This script will perform the following bootstrap steps:"
Write-Host @"
- Check required applications are installed.
- Generate Terraform TFVARS file and create Azure resources for remote Terraform backend.
- Migrate temporary local Terraform backend used during bootstrap process into Azure.
`r
"@

# Check for required applications.
Write-Log -Level "SYS" -Message "** Performing Check: Required applications"
if(Get-RequiredApps | Where-Object { $_.Status -eq "Missing" }) {
    Write-Log -Level "ERR" -Message " - Required applications check failed. Please install missing applications and try again."
    exit 1
}

# Validate Azure CLI authentication.
Write-Log -Level "SYS" -Message "** Performing Check: Validate Azure CLI authenticated session"
$azSession = az account show -o json | ConvertFrom-JSON 2>$null
if (-not $azSession) {
    Write-Log -Level "WRN" -Message " - Not authenticated to Azure CLI. Please run 'az login' and try again."
    exit 1
} else{
    Write-Log -Level "INF" -Message " - Azure CLI logged in as: $($azSession.user.name) [$($azSession.tenantDefaultDomain)]"
}

# Validate Github CLI authentication.
Write-Log -Level "SYS" -Message "** Performing Check: Validate Github CLI authenticated session"
$ghSession = gh api user 2>$null | ConvertFrom-JSON
if (-not $ghSession) {
    Write-Log -Level "WRN" -Message " - Not authenticated to GitHub CLI. Please run 'gh auth login' and try again."
    exit 1
} else{
    Write-Log -Level "INF" -Message " - Github CLI logged in as: $($ghSession.login) [$($ghSession.html_url)]"
}

# Validate local environment variables file.
Write-Log -Level "SYS" -Message "** Performing Check: Validate environment variables file"
if(Test-Path -Path ".\env.psd1" -PathType Leaf) {
    Try{
        $config = Import-PowerShellDataFile -Path $envFile
        Write-Log -Level "INF" -Message " - Local environment variables file found and imported successfully."
    }
    Catch{
        Write-Log -Level "ERR" -Message " - Validation for local environment variables file failed. Please check configuration and try again."
        exit 1
    }
}
else {
    Write-Log -Level "ERR" -Message " - Local environment variables file 'env.psd1' not found. Please create from example file and update values as required."
    exit 1
}

# 