resource "azurerm_resource_group" "main" {
  name     = local.names.resource_group
  location = var.location
  tags     = local.tags
}

# User-assigned managed identity for the API Container App
resource "azurerm_user_assigned_identity" "api" {
  name                = local.names.managed_identity_api
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.tags
}

module "monitoring" {
  source              = "./modules/monitoring"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  log_analytics_name  = local.names.log_analytics
  app_insights_name   = local.names.app_insights
  alert_email         = var.alert_action_group_email
  tags                = local.tags
}

module "key_vault" {
  source              = "./modules/key-vault"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  key_vault_name      = local.names.key_vault
  tenant_id           = var.entra_tenant_id
  api_identity_id     = azurerm_user_assigned_identity.api.principal_id
  tags                = local.tags
}

module "sql" {
  source              = "./modules/sql"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  server_name         = local.names.sql_server
  database_name       = local.names.sql_database
  admin_login         = var.sql_admin_login
  admin_password      = var.sql_admin_password
  sku_name            = var.sql_sku
  log_analytics_id    = module.monitoring.log_analytics_workspace_id
  tags                = local.tags
}

module "redis" {
  source              = "./modules/redis"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  redis_name          = local.names.redis
  sku_name            = var.redis_sku
  family              = var.redis_family
  capacity            = var.redis_capacity
  log_analytics_id    = module.monitoring.log_analytics_workspace_id
  tags                = local.tags
}

module "service_bus" {
  source              = "./modules/service-bus"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  namespace_name      = local.names.service_bus
  sku                 = var.service_bus_sku
  api_identity_id     = azurerm_user_assigned_identity.api.principal_id
  log_analytics_id    = module.monitoring.log_analytics_workspace_id
  tags                = local.tags
}

module "static_web_app" {
  source              = "./modules/static-web-apps"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  app_name            = local.names.static_web_app
  tags                = local.tags
}

module "container_apps" {
  source               = "./modules/container-apps"
  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  env_name             = local.names.container_apps_env
  app_name             = local.names.container_app_api
  container_image      = var.api_container_image
  min_replicas         = var.api_min_replicas
  max_replicas         = var.api_max_replicas
  api_identity_id      = azurerm_user_assigned_identity.api.id
  api_identity_client  = azurerm_user_assigned_identity.api.client_id
  log_analytics_id     = module.monitoring.log_analytics_workspace_id
  log_analytics_key    = module.monitoring.log_analytics_primary_key
  key_vault_uri        = module.key_vault.vault_uri
  sql_connection_secret = module.sql.connection_string_secret_uri
  redis_connection_secret = module.redis.connection_string_secret_uri
  service_bus_fqdn     = module.service_bus.namespace_fqdn
  app_insights_connection = module.monitoring.app_insights_connection_string
  static_web_app_domain = module.static_web_app.default_hostname
  tags                 = local.tags

  depends_on = [
    module.monitoring,
    module.key_vault,
    module.sql,
    module.redis,
    module.service_bus,
  ]
}

# Store connection strings in Key Vault
resource "azurerm_key_vault_secret" "sql_connection" {
  name         = "sql-connection-string"
  value        = module.sql.connection_string
  key_vault_id = module.key_vault.key_vault_id

  depends_on = [module.key_vault]
}

resource "azurerm_key_vault_secret" "redis_connection" {
  name         = "redis-connection-string"
  value        = module.redis.connection_string
  key_vault_id = module.key_vault.key_vault_id

  depends_on = [module.key_vault]
}
