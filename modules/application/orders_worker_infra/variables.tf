variable "from_base" {
  description = "All outputs of the 'storage/base' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "from_key_vaults" {
  description = "All outputs of the 'storage/key_vaults' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "from_postgres" {
  description = "All outputs of the 'storage/postgres' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "from_storage_accounts" {
  description = "All outputs of the 'storage/storage_accounts' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "database_name" {
  type    = string
  default = "orders"
}
