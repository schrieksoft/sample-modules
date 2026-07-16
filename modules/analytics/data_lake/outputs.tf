output "data_lake_uri" {
  value = "abfss://lake@stprod8000.dfs.core.windows.net/"
}

output "filesystem_names" {
  value = ["raw", "curated", "gold"]
}
