variable "from_cluster" {
  description = "All outputs of the 'platform/cluster' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "from_orders_worker_infra" {
  description = "All outputs of the 'application/orders_worker_infra' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "from_redis" {
  description = "All outputs of the 'storage/redis' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "image_tag" {
  type    = string
  default = "v0.9.1"
}

variable "replicas" {
  type    = string
  default = "2"
}
