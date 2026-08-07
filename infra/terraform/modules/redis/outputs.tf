output "connection_string" {
  description = "Redis connection string with password (stored in Key Vault only)"
  value       = "${azurerm_redis_cache.main.hostname}:${azurerm_redis_cache.main.ssl_port},password=${azurerm_redis_cache.main.primary_access_key},ssl=True,abortConnect=False"
  sensitive   = true
}

output "connection_string_secret_uri" {
  description = "Placeholder — resolved after Key Vault secret is created in root module"
  value       = ""
}

output "hostname" {
  value = azurerm_redis_cache.main.hostname
}
