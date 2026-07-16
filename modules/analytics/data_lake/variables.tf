variable "from_private_dns" {
  description = "All outputs of the 'networking/private_dns' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "from_storage_accounts" {
  description = "All outputs of the 'storage/storage_accounts' module, wired by Snap CD."
  type        = any
  default     = {}
}
