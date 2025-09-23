# Bootstrapper: Azure + Terraform + Github Actions

_Automate the bootstrapping process for an existing Azure tenant, using Terraform for IaC and Github Actions for CI/CD._

## Requirements

- Existing Azure tenant with at least **one** active subscription.
- Local applications installed (Azure CLI, Github CLI, Terraform, Git).
- Rename the `example-env.psd1` file to `env.psd1` and update the variable values within.

## Inputs
- See `example-env.psd1` file for required variable values.

## Usage

```powershell
# Create resources.
.\bootstrap-azure-tf-gh.ps1

# Remove resources created by deployment.
.\bootstrap-azure-tf-gh.ps1 -destroy
```

## Actions

### Pre-Checks
- Checks for required applications (Git, Github CLI, Azure CLI, Terraform).
- Validates Azure CLI and Github CLI authentication. 

### Implementation
- Renames provided Azure platform subscription (list item 0) to match naming convention.
- Builds Terraform TFVARS file from Powershell using "env.psd1" variables file.
- Executes Terraform init, validate and plan.
- Presents Terraform plan and prompts users to confirm deployment.

### Deployment
- Creates basic Management Group structure.
- Creates Resources for remote Terraform backend (Resource Group, Storage Account, Container).
- Creates Service Principal with OIDC (Federated) credential in Github.
- Assign RBAC 'Contributor' for Service Principal to 'Core' Management Group.
- Add OIDC details and Terraform backend details to Github Actions Secrets/Variables.

### Migration
- Migrate Terraform state to remote backend in Azure.
- Commit Terraform and Powershell files to created Github repo.

## To Do

- [ ] Migrate local Terraform state to Azure.
- [ ] Upload directory to Github once deployed.
- [ ] Github Actions workflow (YML).
