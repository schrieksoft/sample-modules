variable "settle_seconds" {
  description = "Mock work. Gives jobs a visible duration in the dashboard."
  type        = string
  default     = "5s"
}

resource "time_sleep" "settle" {
  create_duration  = var.settle_seconds
  destroy_duration = var.settle_seconds
}

resource "random_uuid" "azure_runner_id" {
  depends_on = [time_sleep.settle]
}

resource "random_uuid" "k8s_runner_id" {
  depends_on = [time_sleep.settle]
}

resource "random_uuid" "analysis_runner_id" {
  depends_on = [time_sleep.settle]
}

resource "random_uuid" "identity_runner_id" {
  depends_on = [time_sleep.settle]
}
