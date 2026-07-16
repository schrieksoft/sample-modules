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

variable "from_databricks" {
  description = "All outputs of the 'analytics/databricks' module, wired by Snap CD."
  type        = any
  default     = {}
}
