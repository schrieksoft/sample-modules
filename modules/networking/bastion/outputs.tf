output "bastion_host_id" {
  value = random_uuid.bastion_host_id.result
}

output "bastion_fqdn" {
  value = "bastion.prod.internal"
}
