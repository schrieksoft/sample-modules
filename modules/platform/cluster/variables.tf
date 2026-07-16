variable "from_base" {
  description = "All outputs of the 'storage/base' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "from_vpc" {
  description = "All outputs of the 'networking/vpc' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "cluster_name" {
  type    = string
  default = "aks-prod"
}

variable "kubernetes_version" {
  type    = string
  default = "1.32.10"
}
