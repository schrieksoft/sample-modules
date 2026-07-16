variable "from_azure_ad_groups" {
  description = "All outputs of the 'identity/azure_ad_groups' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "from_base" {
  description = "All outputs of the 'storage/base' module, wired by Snap CD."
  type        = any
  default     = {}
}
