variable "from_base" {
  description = "All outputs of the 'storage/base' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "apps_subnet_cidr" {
  type    = string
  default = "10.0.3.0/24"
}

variable "data_subnet_cidr" {
  type    = string
  default = "10.0.4.0/24"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "vpc_name" {
  type    = string
  default = "vnet-prod"
}
