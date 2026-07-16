variable "from_base" {
  description = "All outputs of the 'storage/base' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "from_data_lake" {
  description = "All outputs of the 'analytics/data_lake' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "from_private_dns" {
  description = "All outputs of the 'networking/private_dns' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "warehouse_name" {
  type    = string
  default = "synapse-prod"
}
