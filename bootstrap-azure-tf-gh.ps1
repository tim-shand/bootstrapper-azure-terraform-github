<#
#======================================#
# Bootstrap: Azure (PowerShell)
#======================================#

# DESCRIPTION:
Bootstrap script to prepare Azure tenant for management via Terraform and Github Actions.
This script performs the following tasks:
- Checks for required local applications (Azure CLI, Terraform, Git, GitHub CLI).
- Checks for local environment variables file (env.psd1) and imports configuration.
- Validates Azure CLI authentication, used Azure tenant ID and subscription from current session.
- Validates Github CLI authentication, confirms provided repo name is available (prompts to delete if exists).
- Generates Terraform variable file (TFVARS) from local environment variables.
- Initializes and applies Terraform configuration to create bootstrap resources in Azure.
- Adds bootstrap script and Terraform files into the provided Github repo.

# USAGE:
.\bootstrap-azure-tf-gh.ps1 -envfile ".\env.psd1"
.\bootstrap-azure-tf-gh.ps1 -envfile ".\env.psd1" -destroy
#>

#=============================================#
# VARIABLES
#=============================================#

# General Settings/Variables.
param(
    [switch]$destroy, # Add switch parameter for delete option.
    [Parameter(Mandatory=$true)][string]$envFile # Local variables file ".\env.psd1".
)
$workingDir = "$((Get-Location).Path)\deployments\bootstrap" # Working directory for Terraform files

# Required applications.
$requiredApps = @(
    [PSCustomObject]@{ Name = "Azure CLI"; Command = "az" }
    [PSCustomObject]@{ Name = "Terraform"; Command = "terraform" }
    [PSCustomObject]@{ Name = "Git"; Command = "git" }
    [PSCustomObject]@{ Name = "GitHub CLI"; Command = "gh" }
)

# Determine request action and populate hashtable for logging purposes.
if($destroy){
    $sys_action = @{
        do = "Remove"
        past = "Removed"
        current = "Removing"
        colour = "Magenta"
    }
}
else{
    $sys_action = @{
        do = "Create"
        past = "Created"
        current= "Creating"
        colour = "Green"
    }
}

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
                Write-Log -Level "WRN" -Message "- User declined to proceed."
                return $false
            }
            default {
                Write-Log -Level "WRN" -Message "- Invalid response. Please enter [Y/Yes/N/No]."
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
Write-Host -ForegroundColor Cyan "*** Performing Initial Checks & Validations"

# Validate: Local variables file. Use content for populating TFVARS and other settings.
Write-Log -Level "SYS" -Message "Check: Validate local variables file... "
Try{
    $config = Import-PowerShellDataFile -Path $envFile -ErrorAction Stop
    Write-Host "PASS" -ForegroundColor Green
}
Catch{
    Write-Host "FAIL" -ForegroundColor Red
    Write-Log -Level "ERR" -Message "- Failed to import local variables file '$($envFile)'."
    Write-Log -Level "ERR" -Message "- $_"
    exit 1
}

# Validate: Check install status for required applications.
Write-Log -Level "SYS" -Message "Check: Required applications... "
ForEach($app in $requiredApps) {
    Try{
        # Attempt to get the command for each application to test if installed.
        Get-Command $app.Command > $null 2>&1
    }
    Catch{
        Write-Host "FAIL" -ForegroundColor Red
        Write-Log -Level "ERR" -Message "- Required application '$($app.Name)' is missing. Please install and try again."
        exit 1
    }
} 
Write-Host "PASS" -ForegroundColor Green

# Validate: Github CLI authentication. Check for existing authenticated session.
Write-Log -Level "SYS" -Message "Check: Validate Github CLI authenticated session... "
Try{
    $ghSession = gh api user 2>$null | ConvertFrom-JSON
    Write-Host "PASS" -ForegroundColor Green
    Write-Log -Level "INF" -Message "- Github CLI logged in as: $($ghSession.login) [$($ghSession.html_url)]"

    # Check if repository already exists, prompt to remove and re-create (unless $destroy flag is set).
    $gh_org = ($ghSession.html_url).Replace("https://github.com/","")
    if(-not ($destroy) ){
        $repoCheck = (gh repo list --json name | ConvertFrom-JSON)
        if ($repoCheck | Where-Object {$_.name -eq "$($config.github_config.repo)"} ) {
            Write-Log -Level "WRN" -Message "- Repository '$($gh_org)/$($config.github_config.repo)' already exists."
            Write-Log -Level "WRN" -Message "- If this repository was created outside of this process, it must be removed and re-created to ensure proper configuration."
            Write-Log -Level "WRN" -Message "- If you do not wish to remove this repository, update repository name in variables file. Overwrite?"
            if(Get-UserConfirm){
                Try{
                    gh repo delete "$($gh_org)/$($config.github_config.repo)" --yes 2>$null
                    Write-Log -Level "INF" -Message "- Repository '$($gh_org)/$($config.github_config.repo)' removed successfully."
                }
                Catch{
                    Write-Log -Level "ERR" -Message "- Failed to remove GitHub repository. Please check configuration and try again."
                    Write-Log -Level "ERR" -Message "- $_"
                    exit 1
                }
            }
            else{
                Write-Log -Level "ERR" -Message "- Repository deletion aborted. Please remove manually, or provide a different name and try again."
                exit 1
            }
        }
    }
} 
Catch{
    Write-Host "FAIL" -ForegroundColor Red
    Write-Log -Level "ERR" -Message "- Failed GitHub CLI authentication check. Please run 'gh auth login' and try again."
    exit 1
}

# Validate: Azure CLI authentication. Check for existing authenticated session.
Write-Log -Level "SYS" -Message "Check: Validate Azure CLI authenticated session... "
$azCheck = $( az account show --only-show-errors )
if(-not ( $azCheck ) ){
    Write-Host "FAIL" -ForegroundColor Red
    Write-Log -Level "ERR" -Message "- Failed Azure CLI authentication check. Please run 'az login' manually and try again."
    exit 1
}
else{
    Write-Host "PASS" -ForegroundColor Green
    $azSession = az account show --only-show-errors 2>&1 | ConvertFrom-JSON
    Write-Log -Level "INF" -Message "- Current User: $($azSession.user.name)"
    Write-Log -Level "INF" -Message "- Azure Tenant: $($azSession.tenantDefaultDomain) [$($azSession.tenantId)]"
    Write-Log -Level "INF" -Message "- Subscription: $($azSession.name) [$($azSession.id)]"
}

#================================================#
# MAIN: Stage 2 - Display Intended Actions
#================================================#

Write-Host "Target Azure Environment:" -ForegroundColor Cyan
Write-Host "- Tenant ID: $($azSession.tenantId)"
Write-Host "- Subscription ID: $($azSession.id)"
Write-Host "- Subscription Name: $($azSession.name)"
Write-Host "- Location: $($config.location)"
Write-Host ""
Write-Host "The following resources will be " -ForegroundColor Cyan -NoNewLine
Write-Host "$(($sys_action.past).ToUpper()):" -ForegroundColor $sys_action.colour

Write-Host "- Github:" -ForegroundColor Yellow
Write-Host "  - Target Repository: $gh_org/$($config.github_config.repo)"
Write-Host "  - Secrets: Used by workflows for authentication."
Write-Host "  - Variables: Used by workflows for Terraform remote backend."
Write-Host "- Azure:" -ForegroundColor Yellow
Write-Host "  - Core Management Group: $($config.core_management_group_display_name) ($($config.core_management_group_id))"
Write-Host "  - Entra ID Service Principal: $($config.naming.prefix)-$($config.naming.project)-$($config.naming.service)-sp"
if($destroy){
    Write-Host "  - Resource Group: $($config.naming.prefix)-$($config.naming.project)-$($config.naming.service)-rg" -NoNewline
    Write-Host " (** INCLUDES ALL CHILD RESOURCES **)" -ForegroundColor $sys_action.colour
}
else{
    Write-Host "  - Resource Group: $($config.naming.prefix)-$($config.naming.project)-$($config.naming.service)-rg"
    Write-Host "  - Storage Account: ** Determined during deployment (requires random integers) **"
    Write-Host "  - Storage Container: $($config.naming.prefix)-$($config.naming.project)-$($config.naming.service)-state"
}
Write-Host ""
Write-Log -Level "WRN" -Message "The above resources will be $(($sys_action.past).ToLower()) in the target environment."
if(-not (Get-UserConfirm) ){
    Write-Log -Level "ERR" -Message "User aborted process. Please confirm intended configuration and try again."
    exit 1
} 

#================================================#
# MAIN: Stage 3 - Prepare Terraform
#================================================#

# Generate TFVARS file.
$tfVARS = @"
# Azure Settings.
location = "$($config.location)" # Desired location for resources to be deployed in Azure.
core_management_group_id = "$($config.core_management_group_id)" # Desired ID for the top-level management group (under Tenant Root).
core_management_group_display_name = "$($config.core_management_group_display_name)" # Desired display name for the top-level management group.

# Naming Settings (used for resource names).
naming = {
    prefix = "$($config.naming.prefix)" # Short name of organization ("abc").
    project = "$($config.naming.project)" # Project name for related resources ("platform", "landingzone").
    service = "$($config.naming.service)" # Service name used in the project ("iac", "mgt", "sec").
    environment = "$($config.naming.environment)" # Environment for resources/project ("dev", "tst", "prd", "alz").
}

# Tags (assigned to all bootstrap resources).
tags = {
    Project = "$($config.tags.project)" # Name of the project the resources are for.
    Environment = "$($config.tags.environment)" # dev, tst, prd, alz
    Owner = "$($config.tags.owner)" # Team responsible for the resources.
    Creator = "$($config.tags.creator)" # Person or process that created the resources.
    Deployment = "$(Get-Date -f "yyyyMMdd.HHmmss")" # Timestamp for identifying deployment.
}

# GitHub Settings.
github_config = {
    repo = "$($config.github_config.repo)" # Replace with your new desired GitHub repository name. Must be unique within the organization and empty.
    repo_desc = "$($config.github_config.repo_desc)" # Description for the GitHub repository.
    branch = "$($config.github_config.branch)" # Replace with your preferred branch name.
    visibility = "$($config.github_config.visibility)" # Set to "public" or "private" as required.
}

"@
# Write out TFVARS file (only if not already exists).
if(-not (Test-Path -Path "$workingDir\bootstrap.tfvars") ){
    $tfVARS | Out-File -Encoding utf8 -FilePath "$workingDir\bootstrap.tfvars" -Force
}

# Terraform: Initialize
Write-Log -Level "SYS" -Message "Performing Action: Initialize Terraform configuration... "
if(terraform -chdir="$($workingDir)" init -upgrade){
    Write-Host "PASS" -ForegroundColor Green
} else{
    Write-Host "FAIL" -ForegroundColor Red
    Write-Log -Level "ERR" -Message "- Terraform initialization failed. Please check configuration and try again."
    exit 1
}

# Terraform: Validate
Write-Log -Level "SYS" -Message "Performing Action: Running Terraform validation... "
if(terraform -chdir="$($workingDir)" validate){
    Write-Host "PASS" -ForegroundColor Green
} else{
    Write-Host "FAIL" -ForegroundColor Red
    Write-Log -Level "ERR" -Message "- Terraform validation failed. Please check configuration and try again."
    exit 1
}

#===================================================#
# MAIN: Stage 4 - Execute Terraform (Deploy/Destroy)
#===================================================#

if($destroy){
    # Terraform: Destroy
    Write-Log -Level "WRN" -Message "Terraform will now remove all bootstrap resources. This may take several minutes to complete."
    if(-not (Get-UserConfirm) ){
        Write-Log -Level "ERR" -Message "User aborted process. Please confirm intended configuration and try again."
        exit 1
    }
    else{
        Write-Log -Level "SYS" -Message "Performing Action: Running Terraform destroy... "
        if(terraform -chdir="$($workingDir)" destroy --auto-approve `
            -var-file="bootstrap.tfvars" `
            -var="azure_tenant_id=$($azSession.tenantId)" `
            -var="platform_subscription_id=$($azSession.id)" `
            -var="github_org=$($gh_org)"
        ){
            Write-Host "PASS" -ForegroundColor Green
            Write-Host -ForegroundColor Cyan "`r`n*** Bootstrap Removal Complete! ***`r`n"
        } else{
            Write-Host "FAIL" -ForegroundColor Red
            Write-Log -Level "ERR" -Message "- Terraform plan failed. Please check configuration and try again."
            exit 1
        }
    }
}
else{
    # Terraform: Plan
    Write-Log -Level "SYS" -Message "Performing Action: Running Terraform plan... "
    if(terraform -chdir="$($workingDir)" plan --out=bootstrap.tfplan `
            -var-file="bootstrap.tfvars" `
            -var="azure_tenant_id=$($azSession.tenantId)" `
            -var="platform_subscription_id=$($azSession.id)" `
            -var="github_org=$($gh_org)"
    ){
        Write-Host "PASS" -ForegroundColor Green
        terraform -chdir="$($workingDir)" show "$workingDir\bootstrap.tfplan"
    } else{
        Write-Host "FAIL" -ForegroundColor Red
        Write-Log -Level "ERR" -Message "- Terraform plan failed. Please check configuration and try again."
        exit 1
    }

    # Terraform: Apply
    if(Test-Path -Path "$workingDir\bootstrap.tfplan"){
        Write-Host ""
        Write-Log -Level "WRN" -Message "Terraform will now deploy resources. This may take several minutes to complete."
        if(-not (Get-UserConfirm) ){
            Write-Log -Level "ERR" -Message "User aborted process. Please confirm intended configuration and try again."
            exit 1
        }
        else{
            Write-Log -Level "SYS" -Message "Performing Action: Running Terraform apply... "
            if(terraform -chdir="$($workingDir)" apply bootstrap.tfplan){
                Write-Host "PASS" -ForegroundColor Green
            } else{
                Write-Host "FAIL" -ForegroundColor Red
                Write-Log -Level "ERR" -Message "- Terraform plan failed. Please check configuration and try again."
                exit 1
            }
        }
    } else{
        Write-Log -Level "ERR" -Message "- Terraform plan file missing! Please check configuration and try again."
        exit 1  
    }
}

#================================================#
# MAIN: Stage 5 - Migrate State to Azure
#================================================#

if(-not ($destroy)){
    # Get Github variables from Terraform output.
    Write-Log -Level "SYS" -Message "Retrieving Terraform backend details from output... "
    Try{
        $tf_rg = terraform -chdir="$($workingDir)" output -raw tf_backend_rg_name
        $tf_sa = terraform -chdir="$($workingDir)" output -raw tf_backend_sa_name
        $tf_cn = terraform -chdir="$($workingDir)" output -raw tf_backend_cn_name
        Write-Host "PASS" -ForegroundColor Green
    }
    Catch{
        Write-Host "FAIL" -ForegroundColor Red
        Write-Log -Level "ERR" -Message "- Failed to get Terraform output values. Please check configuration and try again."
        exit 1
    }

    # Generate backend config for state migration.
    $tfBackend = `
@"
terraform {
    backend "azurerm" {
    resource_group_name  = "$($tf_rg)"
    storage_account_name = "$($tf_sa)"
    container_name       = "$($tf_cn)"
    key                  = "bootstrap.tfstate"
    }
}
"@
    $tfBackend | Out-File -Encoding utf8 -FilePath "$workingDir\backend.tf" -Force

    # Terraform: Migrate State
    Write-Log -Level "WRN" -Message "Terraform will now migrate state to Azure."
    if(Get-UserConfirm){
        Write-Log -Level "SYS" -Message "Migrating Terraform state to Azure... "
        if(terraform -chdir="$($workingDir)" init -migrate-state -force-copy -input=false){
            Write-Host "PASS" -ForegroundColor Green
        }
        else{
            Write-Host "FAIL" -ForegroundColor Red
            Write-Log -Level "ERR" -Message "- Failed to migrate Terraform state to Azure."
        }
    }
    else{
        Write-Log -Level "WRN" -Message "- Terraform state migration aborted by user."
        exit 1
    }
}

#================================================#
# MAIN: Stage 6 - Clone to New Repo
#================================================#

if(-not ($destroy) ){

    # Confirm access to remote GitHub repository.
    Write-Log -Level "SYS" -Message "Confirming access to remote GitHub repository ($($gh_org)/$($config.github_config.repo))... "

    if( gh repo view "$($gh_org)/$($config.github_config.repo)" ){
        Write-Host "PASS" -ForegroundColor Green
        $gh_url = (gh repo view "$($gh_org)/$($config.github_config.repo)" --json url | ConvertFrom-JSON).url
    }
    else{
        Write-Host "FAIL" -ForegroundColor Red
        Write-Log -Level "ERR" -Message "- Unable to access target repository. Please ensure access is available and try again."
        exit 1
    }

    # Create temporary folder for repo and initialize Git.
    Write-Log -Level "SYS" -Message "Creating temporary directory for new Git repository... "
    Try{
        $tmpdir = (New-Item -ItemType Directory -Path "..\tmp_git_dir" -Force)
        $file_copy = (Copy-Item -Path ".\*" -Destination $tmpdir.fullname -Recurse -Force -Exclude ".git")
        $git_init = git init $($tmpdir.fullname)
        Write-Host "PASS" -ForegroundColor Green
    }
    Catch{
        Write-Host "FAIL" -ForegroundColor Red
        Write-Log -Level "ERR" -Message "- Failed to create temporary directory for Git. Please check permissions and try again."
        Write-Log -Level "ERR" -Message "- $_"
    }

    # Commit local code to remote repository.
    Write-Log -Level "SYS" -Message "Committing codebase to Git repository ($gh_url)... "
    Try{
        $git = git -C $($tmpdir.fullname) remote add origin $gh_url
        $git = git -C $($tmpdir.fullname) add .
        $git = git -C $($tmpdir.fullname) commit -m "Initial commit."
        $git = git -C $($tmpdir.fullname) push origin main
        Write-Host "PASS" -ForegroundColor Green
    }
    Catch{
        Write-Host "FAIL" -ForegroundColor Red
        Write-Log -Level "ERR" -Message "- Unable to push into repository. Please ensure access is available and try again."
        exit 1
    }

    # Clean Up
    Write-Log -Level "SYS" -Message "Running clean up process... "
    Try{
        $tmpdir = (Remove-Item -Path "..\tmp_git_dir" -Recurse -Force)
        $file_del = (Remove-Item -Path ".\.terraform" -Recurse -Force)
        $file_del = (Remove-Item -Path ".\.terraform.*" -Force)
        $file_del = (Remove-Item -Path ".\*.tfstate*" -Force)
        Write-Host "PASS" -ForegroundColor Green
    }
    Catch{
        Write-Host "FAIL" -ForegroundColor Red
        Write-Log -Level "ERR" -Message "- Failed to clean up all resources. Manual clean up of files may be required."
    }
}

$git, $git_init, $file_copy, $file_del > $null # Shut up VS Code complaining about unreferenced vars.
Write-Host -ForegroundColor Cyan "`r`n*** Bootstrap Deployment Complete! ***`r`n"