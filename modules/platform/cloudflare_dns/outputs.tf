output "zone_id" {
  value = random_uuid.zone_id.result
}

output "zone_name" {
  value = var.dns_zone
}

output "record_fqdns" {
  value = ["api.example.com", "argocd.example.com", "docs.example.com"]
}
