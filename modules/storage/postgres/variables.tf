variable "from_base" {
  description = "All outputs of the 'storage/base' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "from_private_dns" {
  description = "All outputs of the 'networking/private_dns' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "from_vpc" {
  description = "All outputs of the 'networking/vpc' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "postgres_server_name" {
  type    = string
  default = "pg-prod"
}

variable "postgres_version" {
  type    = string
  default = "16"
}
