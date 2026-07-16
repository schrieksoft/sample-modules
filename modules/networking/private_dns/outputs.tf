output "private_dns_zone_id" {
  value = random_uuid.private_dns_zone_id.result
}

output "private_dns_zone_name" {
  value = var.private_dns_zone_name
}
