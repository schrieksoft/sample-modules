output "identity_id" {
  value = random_uuid.identity_id.result
}

output "identity_client_id" {
  value = random_uuid.identity_client_id.result
}

output "database_name" {
  value = var.database_name
}

output "db_connection_secret_ref" {
  value = "https://kv-prod.vault.azure.net/secrets/storefront-conn"
}
