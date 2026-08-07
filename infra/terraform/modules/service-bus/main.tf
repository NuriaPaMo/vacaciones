resource "azurerm_servicebus_namespace" "main" {
  name                = var.namespace_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  minimum_tls_version = "1.2"
  tags                = var.tags
}

# Managed identity RBAC — Azure Service Bus Data Owner for the API identity
resource "azurerm_role_assignment" "api_servicebus_owner" {
  scope                = azurerm_servicebus_namespace.main.id
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = var.api_identity_id
}

# ─── Topics ───────────────────────────────────────────────────────────────────

resource "azurerm_servicebus_topic" "vacation_requests" {
  name         = "vacation-requests"
  namespace_id = azurerm_servicebus_namespace.main.id
  max_message_size_in_kilobytes = 256
  default_message_ttl = "P14D"
}

resource "azurerm_servicebus_topic" "approval_events" {
  name         = "approval-events"
  namespace_id = azurerm_servicebus_namespace.main.id
  default_message_ttl = "P14D"
}

resource "azurerm_servicebus_topic" "capacity_events" {
  name         = "capacity-events"
  namespace_id = azurerm_servicebus_namespace.main.id
  default_message_ttl = "P14D"
}

resource "azurerm_servicebus_topic" "integration_events" {
  name         = "integration-events"
  namespace_id = azurerm_servicebus_namespace.main.id
  default_message_ttl = "P14D"
}

# ─── Subscriptions — vacation-requests ────────────────────────────────────────

resource "azurerm_servicebus_subscription" "vacation_requests_notifications" {
  name               = "notification-handler"
  topic_id           = azurerm_servicebus_topic.vacation_requests.id
  max_delivery_count = 5
  lock_duration      = "PT1M"
  dead_lettering_on_message_expiration = true
}

resource "azurerm_servicebus_subscription" "vacation_requests_capacity" {
  name               = "capacity-management"
  topic_id           = azurerm_servicebus_topic.vacation_requests.id
  max_delivery_count = 5
  lock_duration      = "PT1M"
  dead_lettering_on_message_expiration = true
}

resource "azurerm_servicebus_subscription" "vacation_requests_servicenow" {
  name               = "servicenow-export"
  topic_id           = azurerm_servicebus_topic.vacation_requests.id
  max_delivery_count = 5
  lock_duration      = "PT2M"
  dead_lettering_on_message_expiration = true
}

# ─── Subscriptions — approval-events ─────────────────────────────────────────

resource "azurerm_servicebus_subscription" "approval_events_notifications" {
  name               = "notification-handler"
  topic_id           = azurerm_servicebus_topic.approval_events.id
  max_delivery_count = 5
  lock_duration      = "PT1M"
  dead_lettering_on_message_expiration = true
}

resource "azurerm_servicebus_subscription" "approval_events_capacity" {
  name               = "capacity-management"
  topic_id           = azurerm_servicebus_topic.approval_events.id
  max_delivery_count = 5
  lock_duration      = "PT1M"
  dead_lettering_on_message_expiration = true
}

# ─── Subscriptions — capacity-events ─────────────────────────────────────────

resource "azurerm_servicebus_subscription" "capacity_events_notifications" {
  name               = "notification-handler"
  topic_id           = azurerm_servicebus_topic.capacity_events.id
  max_delivery_count = 5
  lock_duration      = "PT1M"
  dead_lettering_on_message_expiration = true
}

# ─── Subscriptions — integration-events ──────────────────────────────────────

resource "azurerm_servicebus_subscription" "integration_events_notifications" {
  name               = "notification-handler"
  topic_id           = azurerm_servicebus_topic.integration_events.id
  max_delivery_count = 5
  lock_duration      = "PT1M"
  dead_lettering_on_message_expiration = true
}

# ─── Diagnostics ──────────────────────────────────────────────────────────────

resource "azurerm_monitor_diagnostic_setting" "servicebus" {
  name                       = "diag-sb"
  target_resource_id         = azurerm_servicebus_namespace.main.id
  log_analytics_workspace_id = var.log_analytics_id

  enabled_log { category = "OperationalLogs" }
  enabled_log { category = "VNetAndIPFilteringLogs" }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
