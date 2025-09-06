variable "core_mg_id" {
  description = "The ID of the core management group. Used for assigning RBAC."
  type        = string
}

# variable "org_prefix" {
#   description = "The prefix to use for resource nameing."
#   type        = string
# }

# variable "org_project" {
#   description = "The project name to use for resource naming."
#   type        = string
# }

# variable "org_service" {
#   description = "The service name to use for resource naming."
#   type        = string
# }

variable "org_naming" {
  description = "A map of naming parameters to use with resources."
  type        = map(string)
  default     = {}
}

variable "github_config" {
  description = "A map of Github settings."
  type        = map(string)
  default     = {}
}

# variable "github_org" {
#   description = "The Github organization to use for the repository."
#   type        = string
# }

# variable "github_repo" {
#   description = "The Github repository to use for the infrastructure code."
#   type        = string
# }

# variable "github_branch" {
#   description = "The Github repository branch to use for the infrastructure code."
#   type        = string
# }