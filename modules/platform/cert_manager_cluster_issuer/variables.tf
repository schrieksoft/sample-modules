variable "from_cert_manager" {
  description = "All outputs of the 'platform/cert_manager' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "from_cloudflare_dns" {
  description = "All outputs of the 'platform/cloudflare_dns' module, wired by Snap CD."
  type        = any
  default     = {}
}
