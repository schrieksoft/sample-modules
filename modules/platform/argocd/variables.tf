variable "from_cluster" {
  description = "All outputs of the 'platform/cluster' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "from_istio" {
  description = "All outputs of the 'platform/istio' module, wired by Snap CD."
  type        = any
  default     = {}
}
