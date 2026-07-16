output "workspace_id" {
  value = random_uuid.workspace_id.result
}

output "workspace_url" {
  value = "https://adb-8000.11.azuredatabricks.net"
}
