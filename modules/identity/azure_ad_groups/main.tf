variable "settle_seconds" {
  description = "Mock work. Gives jobs a visible duration in the dashboard."
  type        = string
  default     = "5s"
}

resource "time_sleep" "settle" {
  create_duration  = var.settle_seconds
  destroy_duration = var.settle_seconds
}

resource "random_uuid" "platform_team_group_id" {
  depends_on = [time_sleep.settle]
}

resource "random_uuid" "data_team_group_id" {
  depends_on = [time_sleep.settle]
}

resource "random_uuid" "analytics_team_group_id" {
  depends_on = [time_sleep.settle]
}

resource "random_uuid" "product_team_group_id" {
  depends_on = [time_sleep.settle]
}

resource "random_uuid" "security_team_group_id" {
  depends_on = [time_sleep.settle]
}
