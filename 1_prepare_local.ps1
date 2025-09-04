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
.\scripts\bootstrap\bootstrap-azure-terraform-github.ps1
#>

#=============================================#
# VARIABLES
#=============================================#

# Script settings.
$ErrorActionPreference = "Stop" # Set the error action preference to stop on errors.

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

# Function: Check for required applications, fail if not detected.
function Get-RequiredApps {
    $appResults = @()
    ForEach($app in $requiredApps) {
        Try{
            # Attempt to get the command for each application to test if actual installed.
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