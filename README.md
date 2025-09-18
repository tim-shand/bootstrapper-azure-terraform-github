# Bootstrapper: Azure + Terraform + Github Actions

_Automate the bootstrapping process for an existing Azure tenant, using Terraform for IaC and Github Actions for CI/CD._

## Requirements

- Azure tenant with at least **one** active subscription.
- Local applications installed (Azure CLI, Github CLI, Terraform, Git).

## Process

### Preparation
- Check required applications are installed.
- Check for active authenticated sessions (Azure CLI, Github CLI).

### Inputs
- See `example-env.psd1` file for required variable values.

### Usage

```powershell
# Create resources.
.\bootstrap-azure.ps1

# Remove resources created by deployment.
.\bootstrap-azure.ps1 -destroy $true
```

### Actions
- Check/Create Github repository (will prompt to create if missing).
- Clone Terraform files from public "Azure Bootstrapper" Github repository.
- Push cloned files into provided/new repository.
- Build TFVARS file from Powershell "env.psd1" file.
- Rename provided Azure platform subscription.
- Create Management Group structure.
- Create Resources for Terraform backend.
- Create Service Principal.
- Create Service Principal OIDC (Federated) credential.
- Add OIDC details to Github Actions for repository.
- Assign RBAC 'Contributor' for Service Principal to "Core" Management Group.
- Migrate Terraform state to remote backend in Azure.

## To Do

- Terraform backend migration process.
- Github Actions workflow (YML) per deployment.
- Add example file `example-env.psd1`.
- Clean up temporary TF files.