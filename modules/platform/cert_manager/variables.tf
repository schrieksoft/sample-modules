variable "from_cluster" {
  description = "All outputs of the 'platform/cluster' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "cert_manager_version" {
  type    = string
  default = "1.16.2"
}
