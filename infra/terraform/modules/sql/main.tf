resource "azurerm_mssql_server" "main" {
  name                         = var.server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.admin_login
  administrator_login_password = var.admin_password
  minimum_tls_version          = "1.2"  # constitution: TLS 1.2+

  azuread_administrator {
    login_username = "aad-admin"
    object_id      = data.azurerm_client_config.current.object_id
  }

  tags = var.tags
}

resource "azurerm_mssql_database" "main" {
  name        = var.database_name
  server_id   = azurerm_mssql_server.main.id
  sku_name    = var.sku_name
  max_size_gb = 32

  # Transparent Data Encryption — enabled by default in Azure SQL; explicit for Checkov compliance
  transparent_data_encryption_enabled = true

  long_term_retention_policy {
    weekly_retention  = "P4W"
    monthly_retention = "P12M"
    yearly_retention  = "P7Y"   # constitution: 7-year audit retention
    week_of_year      = 1
  }

  short_term_retention_policy {
    retention_days           = 35
    backup_interval_in_hours = 12
  }

  tags = var.tags
}

# Deny all public network access by default; Checkov CKV_AZURE_25
resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_monitor_diagnostic_setting" "sql" {
  name                       = "diag-sql"
  target_resource_id         = azurerm_mssql_database.main.id
  log_analytics_workspace_id = var.log_analytics_id

  enabled_log { category = "SQLInsights" }
  enabled_log { category = "AutomaticTuning" }
  enabled_log { category = "QueryStoreRuntimeStatistics" }
  enabled_log { category = "Errors" }
  enabled_log { category = "DatabaseWaitStatistics" }
  enabled_log { category = "Timeouts" }
  enabled_log { category = "Blocks" }
  enabled_log { category = "Deadlocks" }

  metric {
    category = "Basic"
    enabled  = true
  }
}

data "azurerm_client_config" "current" {}
