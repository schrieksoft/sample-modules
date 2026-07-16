variable "from_istio" {
  description = "All outputs of the 'platform/istio' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "dns_zone" {
  type    = string
  default = "example.com"
}
