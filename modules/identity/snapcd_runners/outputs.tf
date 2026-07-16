output "azure_runner_id" {
  value = random_uuid.azure_runner_id.result
}

output "k8s_runner_id" {
  value = random_uuid.k8s_runner_id.result
}

output "analysis_runner_id" {
  value = random_uuid.analysis_runner_id.result
}

output "identity_runner_id" {
  value = random_uuid.identity_runner_id.result
}
