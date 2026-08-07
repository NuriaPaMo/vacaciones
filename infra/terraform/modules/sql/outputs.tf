output "connection_string" {
  description = "ADO.NET connection string (used by Key Vault secret value)"
  value       = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${var.database_name};Authentication=Active Directory Default;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  sensitive   = true
}

output "connection_string_secret_uri" {
  description = "Placeholder — resolved after Key Vault secret is created in root module"
  value       = ""
}

output "server_fqdn" {
  value = azurerm_mssql_server.main.fully_qualified_domain_name
}
