output "api_url" {
  description = "Container App API URL"
  value       = module.container_apps.api_fqdn
}

output "frontend_url" {
  description = "Azure Static Web App default hostname"
  value       = module.static_web_app.default_hostname
}

output "key_vault_uri" {
  description = "Key Vault URI for application config"
  value       = module.key_vault.vault_uri
}

output "service_bus_fqdn" {
  description = "Service Bus namespace fully qualified domain name"
  value       = module.service_bus.namespace_fqdn
}

output "app_insights_connection_string" {
  description = "Application Insights connection string for OTel exporter"
  value       = module.monitoring.app_insights_connection_string
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID"
  value       = module.monitoring.log_analytics_workspace_id
}

output "api_managed_identity_client_id" {
  description = "Client ID of the API managed identity — used in MSAL client credentials"
  value       = azurerm_user_assigned_identity.api.client_id
}

output "resource_group_name" {
  description = "Name of the main resource group"
  value       = azurerm_resource_group.main.name
}
