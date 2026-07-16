output "warehouse_id" {
  value = random_uuid.warehouse_id.result
}

output "warehouse_fqdn" {
  value = "synapse-prod.sql.azuresynapse.net"
}
