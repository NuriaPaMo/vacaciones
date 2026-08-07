output "api_fqdn" {
  description = "Container App FQDN (without https://)"
  value       = azurerm_container_app.api.latest_revision_fqdn
}

output "container_app_id" {
  value = azurerm_container_app.api.id
}
