# Bootstrapper: Azure + Terraform + Github Actions

_Automate the bootstrapping process for an existing Azure tenant, using Terraform for IaC and Github Actions for CI/CD._

## Requirements

- Existing Azure tenant with at least **one** active subscription.
- Local applications installed (Azure CLI, Github CLI, Terraform, Git).
- Rename the `example-env.psd1` file to `env.psd1` and update the variable values within.

## Inputs
- See `example-env.psd1` file for required variable values.
- Azure Tenant and subscription ID are obtained from current authenticated AzureCLI session.
- Before running the bootstrap script, ensure you are authenticated with the correct target tenant and subscription set.

```bash
# Get current Azure session details.
az account show --output table

# Display all available subscriptions.
az account list --output table

# Change subscription ID
az account set --subscription 1234-5678-1234-5678-1234
```

## Usage

```powershell
# Create resources.
.\bootstrap-azure-tf-gh.ps1

# Remove resources created by deployment.
.\bootstrap-azure-tf-gh.ps1 -destroy
```

## Actions Performed

### Stage 1: Validation and Checks

- [x] Check for required applications.
- [x] Check for local env.psd1 file.
- [x] Check Azure CLI authentication.
- [x] Check Github CLI authentication.

### Stage 2: Bootstrap Deployment

- [x] Create Core Management Group (top-level under tenant root).
- [x] Move platform subscription to `Core` Management Group.
- [x] Create Azure Service Principal with `Contributor` RBAC role on Core MG.
- [x] Create Service Principal with OIDC (Federated) credential for Github.
- [x] Create Resource Group, Storage Account, Storage Container for Terraform remote backend.
- [x] Assign RBAC role `Storage Blob Data Contributor` on Storage Account for Service Principal.
- [x] Create Github repository using current GH CLI session data.

### Stage 3: Migration Process

- [x] Add OIDC and Terraform backend details to Github Actions Secrets/Variables.
- [ ] Builds Terraform TFVARS file from Powershell using "env.psd1" variables file.
- [ ] Executes Terraform init, validate and plan.
- [ ] Presents Terraform plan and prompts users to confirm deployment.

### Stage 4: Clean Up

- [ ] Remove all locally created temporary files.
- [ ] Commit Terraform and Powershell files to created Github repo.