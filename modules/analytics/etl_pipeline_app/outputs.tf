output "pipeline_job_id" {
  value = random_uuid.pipeline_job_id.result
}

output "schedule_cron" {
  value = var.schedule_cron
}
