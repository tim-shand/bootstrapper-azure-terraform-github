variable "azure_tenant_id" {
  description = "The Azure Tenant ID to deploy resources into."
  type        = string
}

variable "sub_platform_ids" {
  description = "A list of platform subscription IDs for the management group structure ['a', 'b', 'c']."
  type        = list(string)
}

variable "sub_workload_ids" {
  description = "A list of workload subscription IDs for the management group structure ['a', 'b', 'c']."
  type        = list(string)
}

variable "location" {
  description = "The Azure location to deploy resources into."
  type        = string
  default     = "australiaeast"
}

variable "org_prefix" {
  description = "The prefix to use for resource nameing."
  type        = string
}

variable "org_project" {
  description = "The project name to use for resource naming."
  type        = string
}

variable "org_service" {
  description = "The service name to use for resource naming."
  type        = string
}

variable "org_tags" {
  description = "A map of tags to apply to resources."
  type        = map(string)
  default     = {}
}

variable "github_org" {
  description = "The Github organization to use for the repository."
  type        = string
}

variable "github_repo" {
  description = "The Github repository to use for the infrastructure code."
  type        = string
}

variable "github_repo_desc" {
  description = "The description of the Github repository used for the infrastructure code."
  type        = string
}

variable "github_branch" {
  description = "The Github repository branch to use for the infrastructure code."
  type        = string
}
