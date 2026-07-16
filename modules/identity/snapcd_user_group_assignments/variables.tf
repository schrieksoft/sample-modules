variable "from_azure_user_group_assignments" {
  description = "All outputs of the 'identity/azure_user_group_assignments' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "from_snapcd_groups" {
  description = "All outputs of the 'identity/snapcd_groups' module, wired by Snap CD."
  type        = any
  default     = {}
}
