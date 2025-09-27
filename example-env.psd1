@{
    <#
    This file contains variables used to generate with Terraform TFVARS files.
    Variables provided in this file are used for reosurce naming purposes.
    NOTE: Ensure that no dynamic values are provided as this will break the import of this file.
    #>

    # Azure Settings.
    location = "australiaeast" # Desired location for resources to be deployed in Azure.
    core_management_group_id = "core-mg" # Desired ID for the top-level management group (under Tenant Root).
    core_management_group_display_name = "Core" # Desired display name for the top-level management group (under Tenant Root).
    
    # Naming Settings (used for resource names).
    naming = @{
        prefix = "abc" # Short name of organization ("abc").
        project = "platform" # Project name for related resources ("platform", "landingzone").
        service = "iac" # Service name used in the project ("iac", "mgt", "sec").
        environment = "dev" # Environment for resources/project ("dev", "tst", "prd", "alz").
    }

    # Tags (assigned to all bootstrap resources).
    tags = @{
        Project = "Platform" # Name of the project the resources are for.
        Environment = "dev" # dev, tst, prd, alz
        Owner = "CloudOps" # Team responsible for the resources.
        Creator = "bootstrap" # Person or process that created the resources.
    }

    # GitHub Settings.
    github_config = @{
        repo = "test-repo-01" # Replace with your new desired GitHub repository name. Must be unique within the organization and empty.
        repo_desc = "Testing bootstrap process for Azure tenant." # Description for the GitHub repository.
        branch = "main" # Replace with your GitHub repository name.
        visibility = "private" # Set to "public" or "private" as required.
    }
}
