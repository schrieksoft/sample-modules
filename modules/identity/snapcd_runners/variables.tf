variable "from_azure_service_principals" {
  description = "All outputs of the 'identity/azure_service_principals' module, wired by Snap CD."
  type        = any
  default     = {}
}
