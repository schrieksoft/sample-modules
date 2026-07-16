variable "from_databricks" {
  description = "All outputs of the 'analytics/databricks' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "from_etl_pipeline_infra" {
  description = "All outputs of the 'analytics/etl_pipeline_infra' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "from_storefront_api_infra" {
  description = "All outputs of the 'application/storefront_api_infra' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "from_warehouse" {
  description = "All outputs of the 'analytics/warehouse' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "schedule_cron" {
  type    = string
  default = "0 2 * * *"
}
