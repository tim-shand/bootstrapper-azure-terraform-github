# Bootstrapper: Azure + Terraform + Github Actions

_Automate the bootstrapping process for an existing Azure tenant, using Terraform for IaC and Github Actions for CI/CD._

## Requirements

- Existing Azure tenant with at least **one** active subscription.
- Local applications installed (Azure CLI, Github CLI, Terraform, Git).
- Rename the `example.psd1` file to `env.psd1` and update the variable values within.

## Process

### Preparation
- Check required applications are installed.
- Check for active authenticated sessions (Azure CLI, Github CLI).

### Inputs
- See `example-env.psd1` file for required variable values.

### Usage

```powershell
# Create resources.
.\bootstrap-azure-tf-gh.ps1

# Remove resources created by deployment.
.\bootstrap-azure-tf-gh.ps1 -destroy
```

### Actions
- Build Terraform TFVARS file from Powershell "env.psd1" file.
- Rename provided Azure platform subscription.
- Create Management Group structure.
- Create Resources for Terraform backend (Resource Group, Storage Account, Container).
- Create Service Principal with OIDC (Federated) credential.
- Add OIDC details and Terraform backend details to Github Actions Secrets/Variables.
- Assign RBAC 'Contributor' for Service Principal to 'Core' Management Group.
- Migrate Terraform state to remote backend in Azure.
- Commit Terraform and Powershell files to created Github repo.

## To Do

- Extract TF Backend resources from TF output.
- Migrate local Terraform state to Azure.
- Upload directory to Github once deployed.
- Github Actions workflow (YML).

