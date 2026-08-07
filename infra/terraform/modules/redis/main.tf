resource "azurerm_redis_cache" "main" {
  name                = var.redis_name
  resource_group_name = var.resource_group_name
  location            = var.location
  capacity            = var.capacity
  family              = var.family
  sku_name            = var.sku_name
  enable_non_ssl_port = false     # TLS only — constitution: TLS 1.2+
  minimum_tls_version = "1.2"
  redis_version       = "7"

  redis_configuration {
    maxmemory_policy = "allkeys-lru"  # evict LRU keys when memory full
  }

  tags = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "redis" {
  name                       = "diag-redis"
  target_resource_id         = azurerm_redis_cache.main.id
  log_analytics_workspace_id = var.log_analytics_id

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
