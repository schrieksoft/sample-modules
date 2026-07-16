variable "settle_seconds" {
  description = "Mock work. Gives jobs a visible duration in the dashboard."
  type        = string
  default     = "5s"
}

resource "time_sleep" "settle" {
  create_duration  = var.settle_seconds
  destroy_duration = var.settle_seconds
}

resource "random_uuid" "vnet_id" {
  depends_on = [time_sleep.settle]
}

resource "random_uuid" "private_subnet_id" {
  depends_on = [time_sleep.settle]
}

resource "random_uuid" "public_subnet_id" {
  depends_on = [time_sleep.settle]
}

resource "random_uuid" "apps_subnet_id" {
  depends_on = [time_sleep.settle]
}

resource "random_uuid" "data_subnet_id" {
  depends_on = [time_sleep.settle]
}
