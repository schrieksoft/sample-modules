output "postgres_server_id" {
  value = random_uuid.postgres_server_id.result
}

output "postgres_fqdn" {
  value = "pg-prod.postgres.database.azure.com"
}

output "postgres_server_name" {
  value = var.postgres_server_name
}
