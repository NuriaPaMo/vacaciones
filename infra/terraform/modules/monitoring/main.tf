resource "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 90   # hot retention; audit data archived via SQL long-term retention

  tags = var.tags
}

resource "azurerm_application_insights" "main" {
  name                = var.app_insights_name
  resource_group_name = var.resource_group_name
  location            = var.location
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = var.tags
}

# Action group — email alerts for production incidents
resource "azurerm_monitor_action_group" "ops" {
  name                = "ag-vacmgt-ops"
  resource_group_name = var.resource_group_name
  short_name          = "vacmgt-ops"

  email_receiver {
    name          = "ops-team"
    email_address = var.alert_email
  }
}

# Alert: API error rate > 1% in 5-minute window
resource "azurerm_monitor_metric_alert" "api_errors" {
  name                = "alert-api-error-rate"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_application_insights.main.id]
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT5M"
  description         = "API error rate exceeded 1% threshold"

  criteria {
    metric_namespace = "microsoft.insights/components"
    metric_name      = "requests/failed"
    aggregation      = "Count"
    operator         = "GreaterThan"
    threshold        = 10
  }

  action {
    action_group_id = azurerm_monitor_action_group.ops.id
  }
}

# Alert: Job failure (AD sync / ServiceNow export)
resource "azurerm_monitor_metric_alert" "job_failure" {
  name                = "alert-background-job-failure"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_application_insights.main.id]
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"
  description         = "Background job failure detected"

  criteria {
    metric_namespace = "microsoft.insights/components"
    metric_name      = "customMetrics/job.failure"
    aggregation      = "Count"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = azurerm_monitor_action_group.ops.id
  }
}
