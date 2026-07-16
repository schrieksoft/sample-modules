variable "settle_seconds" {
  description = "Mock work. Gives jobs a visible duration in the dashboard."
  type        = string
  default     = "5s"
}

resource "time_sleep" "settle" {
  create_duration  = var.settle_seconds
  destroy_duration = var.settle_seconds
}

resource "random_uuid" "cluster_id" {
  depends_on = [time_sleep.settle]
}

resource "random_uuid" "kubelet_identity_id" {
  depends_on = [time_sleep.settle]
}
