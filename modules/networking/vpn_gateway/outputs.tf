output "vpn_gateway_id" {
  value = random_uuid.vpn_gateway_id.result
}

output "vpn_gateway_ip" {
  value = "20.50.120.14"
}
