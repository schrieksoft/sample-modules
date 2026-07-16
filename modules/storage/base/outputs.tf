output "resource_group_name" {
  value = "rg-prod"
}

output "location" {
  value = var.location
}

output "subscription_id" {
  value = random_uuid.subscription_id.result
}

output "tenant_id" {
  value = random_uuid.tenant_id.result
}
