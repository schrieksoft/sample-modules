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

variable "from_sql_server" {
  description = "All outputs of the 'storage/sql_server' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "database_name" {
  type    = string
  default = "storefront"
}

variable "database_sku" {
  type    = string
  default = "S1"
}
