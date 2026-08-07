output "default_hostname" {
  value = azurerm_static_web_app.main.default_host_name
}

output "api_key" {
  description = "Deployment token — used by the frontend CI pipeline"
  value       = azurerm_static_web_app.main.api_key
  sensitive   = true
}

output "static_web_app_id" {
  value = azurerm_static_web_app.main.id
}
