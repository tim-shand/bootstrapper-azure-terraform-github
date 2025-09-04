# Bootstrap: Variables for Azure Management Groups.
variable "org_prefix" {
  description = "Organization prefix for naming resources."
  type        = string
}

variable "sub_platform_ids" {
  description = "A list of platform subscription IDs for the management group structure."
  type        = list(string)
}

variable "sub_workload_ids" {
  description = "A list of workload subscription IDs for the management group structure."
  type        = list(string)
}
