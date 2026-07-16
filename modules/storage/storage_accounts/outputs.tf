output "storage_account_id" {
  value = random_uuid.storage_account_id.result
}

output "storage_account_name" {
  value = "stprod8000"
}

output "blob_endpoint" {
  value = "https://stprod8000.blob.core.windows.net/"
}
