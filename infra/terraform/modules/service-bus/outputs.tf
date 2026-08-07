output "namespace_fqdn" {
  description = "Service Bus namespace FQDN for passwordless connection (Managed Identity)"
  value       = "${azurerm_servicebus_namespace.main.name}.servicebus.windows.net"
}

output "namespace_id" {
  value = azurerm_servicebus_namespace.main.id
}
