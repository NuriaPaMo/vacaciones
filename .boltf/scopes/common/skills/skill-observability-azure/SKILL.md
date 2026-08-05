---
name: skill-observability-azure
description: Implement observability with Application Insights, Azure Monitor, Log Analytics (KQL queries), distributed tracing (OpenTelemetry), alerts, and custom metrics. Use when instrumenting applications, debugging production issues, setting up dashboards, or configuring proactive alerting. Critical because observability enables incident detection, root cause analysis, and performance optimization in production environments.
---

# Observability Azure

## When to Use This Skill

Invoke this skill when you need to:

- **Instrument applications** with Application Insights SDK or OpenTelemetry for telemetry collection (requests, dependencies, exceptions, custom metrics)
- **Debug production issues** using distributed tracing (follow operation_Id across microservices), exception details, performance bottlenecks
- **Write KQL queries** in Log Analytics for incident investigation, performance analysis, or custom dashboards
- **Configure alerts** for proactive monitoring (high error rate, slow response times, dependency failures) with Action Groups (email, webhook, auto-remediation)
- **Build dashboards** with Azure Monitor Workbooks for executive KPIs, operational metrics, or SRE dashboards

**Critical because**: Observability is difference between "we discovered production issue when customer complained" vs "we detected and resolved issue before customer impact." Proper instrumentation (distributed tracing, custom metrics, correlation IDs) enables root cause analysis in minutes instead of hours. Alerts trigger automated remediation (scale-out, restart) or on-call notifications before SLA breaches.

---

## Observability Framework: Golden Signals

### 1. Latency (Response Time)

**Measure**: Request duration, P95/P99 percentiles, dependency call duration

**Implementation**:

- Application Insights: `requests` table, `duration` column
- KQL query: `requests | summarize P95Latency = percentile(duration, 95) by operation_Name`
- Alert: Trigger when P95 latency exceeds SLA threshold (e.g., 3 seconds)

### 2. Traffic (Request Rate)

**Measure**: Requests per second, concurrent users, throughput

**Implementation**:

- Application Insights: `requests` table, count aggregations
- KQL query: `requests | summarize RequestRate = count() by bin(timestamp, 1m)`
- Alert: Anomaly detection on traffic patterns (unexpected spikes or drops)

### 3. Errors (Failure Rate)

**Measure**: HTTP 5xx responses, exceptions, dependency failures

**Implementation**:

- Application Insights: `requests` table (`success == false`), `exceptions` table
- KQL query: `requests | summarize FailureRate = 100.0 * countif(success == false) / count()`
- Alert: Trigger when failure rate exceeds 1-5% (depends on SLA)

### 4. Saturation (Resource Utilization)

**Measure**: CPU, memory, database connections, queue depth

**Implementation**:

- Azure Monitor metrics: `Percentage CPU`, `Memory Working Set`
- Custom metrics: `_telemetryClient.TrackMetric("DatabaseConnectionPoolSize", poolSize)`
- Alert: Trigger when CPU > 80%, memory > 90%, or queue depth grows unbounded

---

## Observability Lifecycle

### Phase 1: Instrumentation (Telemetry Collection)

**Application Insights SDK** (automatic telemetry):

- HTTP requests: Automatically tracked (URL, duration, result code, client IP)
- Dependencies: Automatically tracked (HTTP calls, SQL queries, Cosmos DB, Redis, Service Bus)
- Exceptions: Automatically captured with stack traces
- Cloud role name/instance: Populate Application Map for service topology

**Custom Telemetry**:

- Events: `_telemetryClient.TrackEvent("OrderCreated", properties)`
- Metrics: `_telemetryClient.GetMetric("OrderValue").TrackValue(amount, dimensions)`
- Operations: `_telemetryClient.StartOperation<DependencyTelemetry>("ProcessOrder")` for custom spans
- Correlation: `operation_Id` propagates via W3C Trace Context headers (`traceparent`)

**OpenTelemetry** (vendor-neutral):

- Instrumentation libraries: `FlaskInstrumentor`, `RequestsInstrumentor` (auto-instrumentation)
- Manual spans: `tracer.start_as_current_span("operation_name")`
- Span attributes: `span.set_attribute("product.id", productId)`
- OTLP exporter: Send traces to Application Insights ingestion endpoint

### Phase 2: Querying (Investigation and Analysis)

**Log Analytics KQL**:

- **Incident investigation**: Correlate requests + exceptions by `operation_Id`
- **Performance analysis**: Calculate P95 latency, identify slowest operations
- **Dependency failures**: Query `dependencies` table for failed external calls
- **Distributed tracing**: Reconstruct end-to-end trace across microservices

**Example Queries**:

```kusto
// Failed requests with exception details
requests
| where success == false
| join kind=inner exceptions on operation_Id
| project timestamp, operation_Name, resultCode, exceptionType = type, exceptionMessage = outerMessage

// Slowest operations (P95 latency)
requests
| summarize P95Latency = percentile(duration, 95) by operation_Name
| order by P95Latency desc

// Distributed trace reconstruction
let operationId = "trace-id-from-failed-request";
union requests, dependencies, traces, exceptions
| where operation_Id == operationId
| order by timestamp asc
```

### Phase 3: Alerting (Proactive Monitoring)

**Metric Alerts** (fast, low-latency):

- Based on platform metrics (`requests/failed`, `requests/duration`)
- Evaluation frequency: 1-5 minutes
- Use for: High failure rate, slow response times, high CPU/memory

**Log Alerts** (flexible, KQL-based):

- Based on KQL queries (custom logic, multi-table joins)
- Evaluation frequency: 5-15 minutes
- Use for: Complex conditions (e.g., dependency failure rate > 10% AND request duration > 3s)

**Action Groups**:

- Notifications: Email, SMS, push notifications
- Webhooks: Slack, Microsoft Teams, PagerDuty integration
- Automation: Azure Functions for auto-remediation (scale-out, restart app), Logic Apps for complex workflows

### Phase 4: Visualization (Dashboards and Reports)

**Azure Monitor Workbooks**:

- Interactive dashboards with parameters (time range, environment, service)
- KQL-based charts (time series, pie charts, column charts, heatmaps)
- Cross-resource queries (combine multiple Application Insights resources)
- Drill-downs and filters for investigation

**Application Map**:

- Visualize service topology and dependencies
- Color-coded health indicators (green = healthy, red = high failure rate)
- Click service node → view requests, dependencies, failures

**Live Metrics Stream**:

- Real-time telemetry (requests per second, failure rate, CPU, memory)
- Low-latency monitoring (1-second refresh)
- Useful during deployments or incident response

---

## How to Proceed

1. **Instrument Application**:
   - .NET → Add `Microsoft.ApplicationInsights.AspNetCore` NuGet package, configure connection string
   - Python → Use OpenTelemetry (`opentelemetry-sdk`, `opentelemetry-exporter-otlp`) with OTLP exporter to Application Insights
   - Node.js → Add `applicationinsights` npm package or OpenTelemetry
   - Add telemetry initializer to set cloud role name (enables Application Map)

2. **Validate Telemetry Flow**:
   - Navigate to Application Insights in Azure Portal
   - Check Live Metrics Stream (should see requests, dependencies within 1-2 seconds)
   - Run sample requests, verify telemetry appears in Logs (may take 2-3 minutes for initial ingestion)

3. **Set Up Distributed Tracing**:
   - Verify `operation_Id` propagates across services (check HTTP headers: `traceparent`)
   - Use Application Map to visualize service topology
   - Test end-to-end trace: trigger request, find `operation_Id`, reconstruct trace with KQL

4. **Configure Alerts**:
   - Start with Golden Signals: latency (P95 > 3s), traffic (anomaly detection), errors (failure rate > 5%), saturation (CPU > 80%)
   - Create Action Group (email + webhook to Slack/Teams)
   - Test alerts: intentionally trigger condition (simulate high failure rate), verify notification received

5. **Build Dashboards**:
   - Create Azure Monitor Workbook with KQL queries (request rate, failure rate, P95 latency, dependency failures)
   - Add parameters (time range, environment filter)
   - Pin workbook to Azure Dashboard for team visibility

6. **Review Bundled Code Examples**:
   - `references/code-examples.md`: 6 complete examples (Application Insights .NET instrumentation, OpenTelemetry Python tracing, KQL queries, alert rules with Bicep, custom metrics, correlation ID propagation)

7. **Consult Official Documentation**:
   - `references/microsoft-learn.md`: Application Insights SDK guides, OpenTelemetry integration, KQL reference, alerting best practices, workbook templates

8. **Validate with Constitution**:
   - Check `memory/constitution.md` Article XIV (Observability & Monitoring) for required telemetry, alert thresholds, dashboard standards
   - Document observability architecture as ADR if introducing custom metrics schema or distributed tracing strategy

---

**Remember**: "You can't fix what you can't see." Invest in observability early (instrumentation in every service, distributed tracing, alerts for Golden Signals). Cost-optimize with sampling (adaptive sampling reduces volume 90% while maintaining accuracy), retention policies (default 90 days, adjust per compliance), and metric pre-aggregation (`GetMetric` API). Monitor alert noise (reduce false positives with proper thresholds, use dynamic thresholds for adaptive alerting).
