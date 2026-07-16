output "redis_id" {
  value = random_uuid.redis_id.result
}

output "redis_hostname" {
  value = "redis-prod.redis.cache.windows.net"
}

output "redis_connection_string_ref" {
  value = "https://kv-prod.vault.azure.net/secrets/redis-conn"
}
