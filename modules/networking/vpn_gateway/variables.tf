variable "from_azure_ad_groups" {
  description = "All outputs of the 'identity/azure_ad_groups' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "from_vpc" {
  description = "All outputs of the 'networking/vpc' module, wired by Snap CD."
  type        = any
  default     = {}
}
