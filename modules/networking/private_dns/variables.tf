variable "from_vpc" {
  description = "All outputs of the 'networking/vpc' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "private_dns_zone_name" {
  type    = string
  default = "prod.internal"
}
