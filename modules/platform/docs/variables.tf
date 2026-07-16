variable "from_base" {
  description = "All outputs of the 'storage/base' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "from_cert_manager_cluster_issuer" {
  description = "All outputs of the 'platform/cert_manager_cluster_issuer' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "from_cloudflare_dns" {
  description = "All outputs of the 'platform/cloudflare_dns' module, wired by Snap CD."
  type        = any
  default     = {}
}
