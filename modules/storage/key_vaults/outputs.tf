output "akv_id" {
  value = random_uuid.akv_id.result
}

output "akv_url" {
  value = "https://kv-prod.vault.azure.net/"
}
