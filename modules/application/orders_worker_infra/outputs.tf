output "identity_id" {
  value = random_uuid.identity_id.result
}

output "database_name" {
  value = var.database_name
}

output "queue_name" {
  value = "orders"
}

output "db_connection_secret_ref" {
  value = "https://kv-prod.vault.azure.net/secrets/orders-conn"
}

output "queue_connection_secret_ref" {
  value = "https://kv-prod.vault.azure.net/secrets/orders-queue-conn"
}
