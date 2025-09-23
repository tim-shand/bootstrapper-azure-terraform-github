@{
    <#
    This file contains variables used to generate with Terraform TFVARS files.
    Variables provided in this file are used for reosurce naming purposes.
    NOTE: Ensure that no dynamic values are provided as this will break the import of this file.
    #>

    # Azure Settings.
    azure_tenant_id = "12345678-1234-1234-1234-123456789" # Target Azure tenant ID.
    location = "australiaeast" # Desired location for resources to be deployed in Azure.
    platform_subscription_ids = @( # List of existing platform subscriptions (to be moved to platforms management group).
        "12345678-1234-1234-1234-123456789"
    )
    workload_subscription_ids = @( # List of existing workload subscriptions (to be moved to workloads management group).
        "98765432-9876-9876-9876-987654321"
    )
    core_management_group_id = "core" # Desired ID for the top-level management group (under Tenant Root).
    core_management_group_display_name = "Core" # Desired display name for the top-level management group (under Tenant Root).
    
    # Naming Settings (used for resource names).
    naming = @{
        prefix = "abc" # Short name of organization ("abc").
        project = "platform" # Project name for related resources ("platform", "landingzone").
        service = "iac" # Service name used in the project ("iac", "mgt", "sec").
        environment = "alz" # Environment for resources/project ("dev", "tst", "prd", "alz").
    }

    # Tags (assigned to all bootstrap resources).
    tags = @{
        Project = "Platform-IaC" # Name of the project the resources are for.
        Environment = "alz" # dev, tst, prd, alz
        Owner = "CloudOps" # Team responsible for the resources.
        Creator = "bootstrap" # Person or process that created the resources.
        Created = "" # Populated at runtime.
    }

    # GitHub Settings.
    github_config = @{
        org = "github-org" # Replace with your GitHub organization name.
        repo = "test-repo-01" # Replace with your new desired GitHub repository name. Must be unique within the organization and empty.
        repo_desc = "Bootstrap repo for Azure tenant." # Description for the GitHub repository.
        branch = "main" # Replace with your GitHub repository name.
        visibility = "private" # Set to "public" or "private" as required.
    }
}
