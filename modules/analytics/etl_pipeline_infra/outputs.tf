output "job_cluster_id" {
  value = random_uuid.job_cluster_id.result
}

output "lake_sas_secret_ref" {
  value = "https://kv-prod.vault.azure.net/secrets/lake-sas"
}
