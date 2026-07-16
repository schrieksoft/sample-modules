output "cluster_name" {
  value = var.cluster_name
}

output "cluster_id" {
  value = random_uuid.cluster_id.result
}

output "kubelet_identity_id" {
  value = random_uuid.kubelet_identity_id.result
}

output "oidc_issuer_url" {
  value = "https://westeurope.oic.prod-aks.azure.com/8000/"
}

output "node_resource_group" {
  value = "MC_rg-prod_aks-prod_westeurope"
}
