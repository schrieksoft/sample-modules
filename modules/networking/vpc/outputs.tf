output "vnet_id" {
  value = random_uuid.vnet_id.result
}

output "private_subnet_id" {
  value = random_uuid.private_subnet_id.result
}

output "public_subnet_id" {
  value = random_uuid.public_subnet_id.result
}

output "apps_subnet_id" {
  value = random_uuid.apps_subnet_id.result
}

output "data_subnet_id" {
  value = random_uuid.data_subnet_id.result
}

output "private_subnet_cidr" {
  value = var.private_subnet_cidr
}
