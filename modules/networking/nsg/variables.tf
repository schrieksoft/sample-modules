variable "from_vpc" {
  description = "All outputs of the 'networking/vpc' module, wired by Snap CD."
  type        = any
  default     = {}
}
