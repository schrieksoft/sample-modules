variable "from_cloudflare_dns" {
  description = "All outputs of the 'platform/cloudflare_dns' module, wired by Snap CD."
  type        = any
  default     = {}
}

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

variable "from_storefront_api_infra" {
  description = "All outputs of the 'application/storefront_api_infra' module, wired by Snap CD."
  type        = any
  default     = {}
}

variable "image_tag" {
  type    = string
  default = "v1.4.0"
}

variable "replicas" {
  type    = string
  default = "3"
}
