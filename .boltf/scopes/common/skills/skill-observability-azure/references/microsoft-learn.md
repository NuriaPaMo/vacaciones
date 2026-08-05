# Observability Azure - Microsoft Learn Resources

Curated official Microsoft documentation for implementing observability with Application Insights, Azure Monitor, Log Analytics, distributed tracing, and alerting.

---

## Application Insights

### Core Documentation

- [What is Application Insights?](https://learn.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview) - Application Insights overview and capabilities
- [Application Insights for .NET applications](https://learn.microsoft.com/en-us/azure/azure-monitor/app/asp-net-core) - ASP.NET Core instrumentation
- [Application Insights for Node.js](https://learn.microsoft.com/en-us/azure/azure-monitor/app/nodejs) - Node.js instrumentation
- [Application Insights for Python](https://learn.microsoft.com/en-us/azure/azure-monitor/app/opencensus-python) - Python instrumentation with OpenCensus

### Instrumentation

- [Add Application Insights SDK](https://learn.microsoft.com/en-us/azure/azure-monitor/app/asp-net-core#add-application-insights-sdk) - SDK installation and configuration
- [TelemetryClient API](https://learn.microsoft.com/en-us/azure/azure-monitor/app/api-custom-events-metrics) - Custom events and metrics
- [Telemetry initializers](https://learn.microsoft.com/en-us/azure/azure-monitor/app/api-filtering-sampling#telemetry-initializers) - Add custom properties to all telemetry
- [Sampling](https://learn.microsoft.com/en-us/azure/azure-monitor/app/sampling) - Adaptive sampling to reduce telemetry volume

### Distributed Tracing

- [Distributed tracing in Application Insights](https://learn.microsoft.com/en-us/azure/azure-monitor/app/distributed-tracing) - End-to-end transaction tracking
- [Correlation in Application Insights](https://learn.microsoft.com/en-us/azure/azure-monitor/app/correlation) - operation_Id and correlation telemetry
- [Application Map](https://learn.microsoft.com/en-us/azure/azure-monitor/app/app-map) - Visualize application topology and dependencies
- [Transaction diagnostics](https://learn.microsoft.com/en-us/azure/azure-monitor/app/transaction-diagnostics) - End-to-end trace view

---

## OpenTelemetry Integration

### Core Documentation

- [OpenTelemetry overview](https://learn.microsoft.com/en-us/azure/azure-monitor/app/opentelemetry-overview) - Azure Monitor OpenTelemetry support
- [Enable OpenTelemetry for .NET](https://learn.microsoft.com/en-us/azure/azure-monitor/app/opentelemetry-enable?tabs=net) - .NET OpenTelemetry configuration
- [Enable OpenTelemetry for Python](https://learn.microsoft.com/en-us/azure/azure-monitor/app/opentelemetry-enable?tabs=python) - Python OpenTelemetry configuration
- [Enable OpenTelemetry for JavaScript](https://learn.microsoft.com/en-us/azure/azure-monitor/app/opentelemetry-enable?tabs=nodejs) - Node.js OpenTelemetry configuration

### Distributed Tracing

- [W3C Trace Context](https://www.w3.org/TR/trace-context/) - W3C standard for trace context propagation
- [OpenTelemetry tracing](https://opentelemetry.io/docs/concepts/signals/traces/) - OpenTelemetry tracing concepts
- [Configure sampling](https://learn.microsoft.com/en-us/azure/azure-monitor/app/opentelemetry-configuration#sampling) - OpenTelemetry sampling configuration

---

## Azure Monitor

### Core Documentation

- [Azure Monitor overview](https://learn.microsoft.com/en-us/azure/azure-monitor/overview) - Complete Azure Monitor platform
- [Azure Monitor metrics](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/data-platform-metrics) - Metrics collection and storage
- [Azure Monitor Logs](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/data-platform-logs) - Log data collection and querying
- [Insights and curated visualizations](https://learn.microsoft.com/en-us/azure/azure-monitor/insights/insights-overview) - Application Insights, Container Insights, VM Insights

### Workbooks

- [Azure Monitor Workbooks](https://learn.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-overview) - Interactive reports and dashboards
- [Create workbook](https://learn.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-create-workbook) - Build custom dashboards
- [Workbook templates](https://learn.microsoft.com/en-us/azure/azure-monitor/visualize/workbooks-templates) - Pre-built workbook gallery

---

## Log Analytics and KQL

### Core Documentation

- [Log Analytics overview](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/log-analytics-overview) - Query telemetry with KQL
- [Get started with Log Analytics](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/log-analytics-tutorial) - Log Analytics tutorial
- [Kusto Query Language (KQL) overview](https://learn.microsoft.com/en-us/azure/data-explorer/kusto/query/) - KQL reference documentation

### KQL Query Examples

- [Useful KQL queries](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/example-queries) - Sample KQL queries for common scenarios
- [Aggregation functions](https://learn.microsoft.com/en-us/azure/data-explorer/kusto/query/aggregation-functions) - sum, avg, percentile, count
- [Time series analysis](https://learn.microsoft.com/en-us/azure/data-explorer/kusto/query/time-series-analysis) - Time-based aggregations and anomaly detection
- [Join operator](https://learn.microsoft.com/en-us/azure/data-explorer/kusto/query/join-operator) - Correlate multiple tables

---

## Alerting

### Core Documentation

- [Azure Monitor alerts overview](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-overview) - Alerting concepts and types
- [Metric alerts](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-metric-overview) - Metric-based alerting
- [Log alerts](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-log) - KQL query-based alerting
- [Activity log alerts](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-activity-log) - Azure resource operation alerts

### Action Groups

- [Action groups](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/action-groups) - Notification and automation actions
- [Create action group](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/action-groups-create) - Configure email, SMS, webhook, Logic Apps
- [Common alert schema](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-common-schema) - Standardized alert payload format

### Alert Rules

- [Create metric alert rule](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-create-metric-alert-rule) - Metric-based alert configuration
- [Create log alert rule](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-create-log-alert-rule) - KQL-based alert configuration
- [Alert rule best practices](https://learn.microsoft.com/en-us/azure/azure-monitor/best-practices-alerts) - Alerting strategy and optimization

---

## Custom Metrics

### Core Documentation

- [Custom metrics in Application Insights](https://learn.microsoft.com/en-us/azure/azure-monitor/app/api-custom-events-metrics#trackmetric) - TrackMetric API
- [GetMetric API](https://learn.microsoft.com/en-us/azure/azure-monitor/app/get-metric) - Pre-aggregated metrics (more efficient)
- [Metric dimensions](https://learn.microsoft.com/en-us/azure/azure-monitor/app/get-metric#metric-dimensions) - Multi-dimensional metrics

### Best Practices

- [Performance considerations](https://learn.microsoft.com/en-us/azure/azure-monitor/app/api-custom-events-metrics#performance-considerations) - Optimize telemetry volume
- [Sampling](https://learn.microsoft.com/en-us/azure/azure-monitor/app/sampling-classic-api) - Reduce telemetry cost with sampling

---

## Availability Testing

### Core Documentation

- [Availability tests overview](https://learn.microsoft.com/en-us/azure/azure-monitor/app/availability-overview) - Monitor application availability
- [URL ping test](https://learn.microsoft.com/en-us/azure/azure-monitor/app/monitor-web-app-availability) - Simple HTTP endpoint monitoring
- [Multi-step web test](https://learn.microsoft.com/en-us/azure/azure-monitor/app/availability-multistep) - Complex user flow testing
- [TrackAvailability API](https://learn.microsoft.com/en-us/azure/azure-monitor/app/availability-azure-functions) - Custom availability tests with Azure Functions

---

## Performance Profiling

### Core Documentation

- [Application Insights Profiler](https://learn.microsoft.com/en-us/azure/azure-monitor/profiler/profiler-overview) - Profile production code performance
- [Enable Profiler](https://learn.microsoft.com/en-us/azure/azure-monitor/profiler/profiler) - Profiler setup for App Service, VMs, Container Apps
- [Snapshot Debugger](https://learn.microsoft.com/en-us/azure/azure-monitor/snapshot-debugger/snapshot-debugger) - Debug production exceptions with snapshots

---

## Live Metrics Stream

### Core Documentation

- [Live Metrics Stream](https://learn.microsoft.com/en-us/azure/azure-monitor/app/live-stream) - Real-time telemetry visualization
- [Secure Live Metrics Stream](https://learn.microsoft.com/en-us/azure/azure-monitor/app/live-stream#secure-the-control-channel) - Authenticate Live Metrics

---

## Diagnostic Settings and Log Forwarding

### Core Documentation

- [Diagnostic settings](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings) - Forward Azure resource logs to Log Analytics, Storage, Event Hubs
- [Resource logs](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/resource-logs) - Azure resource log categories
- [Platform logs](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/platform-logs-overview) - Activity logs, resource logs, Azure AD logs

---

## Best Practices

### Observability Strategy

- [Design for observability](https://learn.microsoft.com/en-us/azure/architecture/best-practices/monitoring) - Azure Architecture Center guidance
- [Monitoring and diagnostics](https://learn.microsoft.com/en-us/azure/architecture/best-practices/monitoring) - Best practices for production monitoring
- [Cost optimization](https://learn.microsoft.com/en-us/azure/azure-monitor/best-practices-cost) - Reduce monitoring costs with sampling, retention policies

### Security

- [Secure Application Insights](https://learn.microsoft.com/en-us/azure/azure-monitor/app/ip-addresses) - IP addresses, firewall rules
- [Role-based access control](https://learn.microsoft.com/en-us/azure/azure-monitor/roles-permissions-security) - RBAC for monitoring data
- [Workspace-based Application Insights](https://learn.microsoft.com/en-us/azure/azure-monitor/app/create-workspace-resource) - Centralized Log Analytics workspace

---

## Troubleshooting

### Common Issues

- [Troubleshoot Application Insights](https://learn.microsoft.com/en-us/azure/azure-monitor/app/troubleshoot) - Common SDK issues
- [Missing telemetry](https://learn.microsoft.com/en-us/azure/azure-monitor/app/asp-net-troubleshoot-no-data) - Diagnose missing data
- [Sampling impact](https://learn.microsoft.com/en-us/azure/azure-monitor/app/sampling-classic-api#how-sampling-works) - Understand sampling effects on metrics

---

**Note**: Always reference official Microsoft Learn documentation for up-to-date Application Insights SDK versions, KQL syntax, and Azure Monitor feature availability. Cross-reference with OpenTelemetry documentation for vendor-neutral instrumentation.
