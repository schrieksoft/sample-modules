output "sql_server_id" {
  value = random_uuid.sql_server_id.result
}

output "sql_server_fqdn" {
  value = "sql-prod.database.windows.net"
}

output "sql_server_name" {
  value = var.sql_server_name
}
