output "nsg_id" {
  value = random_uuid.nsg_id.result
}

output "nsg_name" {
  value = "nsg-prod"
}
