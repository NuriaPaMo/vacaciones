resource "azurerm_container_app_environment" "main" {
  name                       = var.env_name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  log_analytics_workspace_id = var.log_analytics_id
  tags                       = var.tags
}

resource "azurerm_container_app" "api" {
  name                         = var.app_name
  resource_group_name          = var.resource_group_name
  container_app_environment_id = azurerm_container_app_environment.main.id
  revision_mode                = "Single"  # rolling update — replace old revision on deploy
  tags                         = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.api_identity_id]
  }

  ingress {
    external_enabled = true
    target_port      = 8080
    transport        = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = "api"
      image  = var.container_image
      cpu    = 0.5
      memory = "1Gi"

      # All secrets sourced from Key Vault via managed identity — no plaintext values
      env {
        name  = "AZURE_CLIENT_ID"
        value = var.api_identity_client
      }
      env {
        name        = "ConnectionStrings__DefaultConnection"
        secret_name = "sql-connection-string"
      }
      env {
        name        = "ConnectionStrings__Redis"
        secret_name = "redis-connection-string"
      }
      env {
        name  = "ServiceBus__FullyQualifiedNamespace"
        value = var.service_bus_fqdn
      }
      env {
        name  = "KeyVault__Uri"
        value = var.key_vault_uri
      }
      env {
        name        = "APPLICATIONINSIGHTS_CONNECTION_STRING"
        secret_name = "appinsights-connection-string"
      }
      env {
        name  = "AllowedOrigins__0"
        value = "https://${var.static_web_app_domain}"
      }

      liveness_probe {
        path             = "/health/live"
        port             = 8080
        transport        = "HTTP"
        initial_delay    = 15
        period_seconds   = 30
        failure_count_threshold = 3
      }

      readiness_probe {
        path             = "/health/ready"
        port             = 8080
        transport        = "HTTP"
        initial_delay    = 10
        period_seconds   = 15
      }
    }

    # Scale on HTTP requests
    http_scale_rule {
      name                = "http-scaling"
      concurrent_requests = "50"
    }
  }

  secret {
    name  = "sql-connection-string"
    # References Key Vault secret URI via managed identity — no plaintext in Terraform state
    identity = var.api_identity_id
    key_vault_secret_uri = var.sql_connection_secret
  }

  secret {
    name  = "redis-connection-string"
    identity = var.api_identity_id
    key_vault_secret_uri = var.redis_connection_secret
  }

  secret {
    name  = "appinsights-connection-string"
    value = var.app_insights_connection
  }
}
