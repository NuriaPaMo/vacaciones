# Observability Azure - Code Examples

Complete examples demonstrating Application Insights instrumentation, Azure Monitor alerting, Log Analytics KQL queries, distributed tracing with OpenTelemetry, and custom metrics for production observability.

---

## Example 1: Application Insights Instrumentation (.NET)

**Pattern**: Instrument ASP.NET Core application with Application Insights SDK for automatic telemetry (requests, dependencies, exceptions) and custom metrics/events.

**When to Use**: .NET applications deployed to Azure, automatic dependency tracking (HTTP, SQL, Cosmos DB), distributed tracing with correlation IDs.

```csharp
// Program.cs
using Microsoft.ApplicationInsights.Extensibility;

var builder = WebApplication.CreateBuilder(args);

// Add Application Insights telemetry
builder.Services.AddApplicationInsightsTelemetry(options =>
{
    options.ConnectionString = builder.Configuration["ApplicationInsights:ConnectionString"];
    options.EnableAdaptiveSampling = true;
    options.EnableQuickPulseMetricStream = true; // Live Metrics Stream
});

// Add telemetry initializer for custom properties
builder.Services.AddSingleton<ITelemetryInitializer, CustomTelemetryInitializer>();

builder.Services.AddControllers();

var app = builder.Build();

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();

// CustomTelemetryInitializer.cs
using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.Extensibility;

public class CustomTelemetryInitializer : ITelemetryInitializer
{
    public void Initialize(ITelemetry telemetry)
    {
        // Add custom properties to all telemetry
        telemetry.Context.GlobalProperties["Environment"] = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Unknown";
        telemetry.Context.GlobalProperties["ServiceVersion"] = "1.0.0";

        // Set cloud role name for Application Map
        telemetry.Context.Cloud.RoleName = "OrderService";
        telemetry.Context.Cloud.RoleInstance = Environment.MachineName;
    }
}

// Controllers/OrdersController.cs
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/[controller]")]
public class OrdersController : ControllerBase
{
    private readonly TelemetryClient _telemetryClient;
    private readonly ILogger<OrdersController> _logger;

    public OrdersController(TelemetryClient telemetryClient, ILogger<OrdersController> logger)
    {
        _telemetryClient = telemetryClient;
        _logger = logger;
    }

    [HttpPost]
    public async Task<IActionResult> CreateOrder([FromBody] CreateOrderRequest request)
    {
        // Track custom event
        _telemetryClient.TrackEvent("OrderCreationStarted", new Dictionary<string, string>
        {
            { "CustomerId", request.CustomerId },
            { "OrderValue", request.TotalAmount.ToString("F2") }
        });

        // Track custom metric
        _telemetryClient.TrackMetric("OrderValue", request.TotalAmount);

        try
        {
            // Simulate order processing with custom operation tracking
            using var operation = _telemetryClient.StartOperation<DependencyTelemetry>("ProcessOrder");
            operation.Telemetry.Type = "InternalOperation";
            operation.Telemetry.Data = $"Customer: {request.CustomerId}";

            await Task.Delay(100); // Simulated processing

            // Dependency call (automatically tracked, but can add custom properties)
            var httpClient = new HttpClient();
            using var dependencyOperation = _telemetryClient.StartOperation<DependencyTelemetry>("CallPaymentService");
            dependencyOperation.Telemetry.Type = "HTTP";
            dependencyOperation.Telemetry.Target = "https://payment-service.example.com";

            try
            {
                var response = await httpClient.PostAsJsonAsync("https://payment-service.example.com/charge",
                    new { CustomerId = request.CustomerId, Amount = request.TotalAmount });
                response.EnsureSuccessStatusCode();

                dependencyOperation.Telemetry.Success = true;
                dependencyOperation.Telemetry.ResultCode = ((int)response.StatusCode).ToString();
            }
            catch (HttpRequestException ex)
            {
                dependencyOperation.Telemetry.Success = false;
                dependencyOperation.Telemetry.ResultCode = "500";

                // Track exception with custom properties
                _telemetryClient.TrackException(ex, new Dictionary<string, string>
                {
                    { "CustomerId", request.CustomerId },
                    { "Operation", "PaymentServiceCall" }
                });

                throw;
            }

            operation.Telemetry.Success = true;

            // Track successful order creation
            _telemetryClient.TrackEvent("OrderCreated", new Dictionary<string, string>
            {
                { "OrderId", Guid.NewGuid().ToString() },
                { "CustomerId", request.CustomerId }
            });

            _logger.LogInformation("Order created successfully for customer {CustomerId}", request.CustomerId);

            return Ok(new { OrderId = Guid.NewGuid() });
        }
        catch (Exception ex)
        {
            // Exception automatically tracked, but add custom severity
            _telemetryClient.TrackException(ex, new Dictionary<string, string>
            {
                { "Severity", "Critical" },
                { "CustomerId", request.CustomerId }
            });

            _logger.LogError(ex, "Failed to create order for customer {CustomerId}", request.CustomerId);

            return StatusCode(500, "Order creation failed");
        }
    }

    [HttpGet("health")]
    public IActionResult HealthCheck()
    {
        // Track availability (custom availability test)
        var availability = new AvailabilityTelemetry
        {
            Name = "OrderService Health Check",
            RunLocation = Environment.MachineName,
            Success = true,
            Duration = TimeSpan.FromMilliseconds(50)
        };

        _telemetryClient.TrackAvailability(availability);

        return Ok("Healthy");
    }
}

public record CreateOrderRequest(string CustomerId, decimal TotalAmount);
```

**Explanation**: Application Insights SDK automatically tracks HTTP requests, dependencies (HTTP calls, SQL queries, Cosmos DB), exceptions. Custom telemetry (events, metrics, operations) adds business context. `TelemetryClient.StartOperation` creates nested operations with automatic correlation IDs (propagated via HTTP headers). Cloud role name/instance populate Application Map for distributed tracing visualization. Adaptive sampling reduces telemetry volume while maintaining statistical accuracy.

---

## Example 2: OpenTelemetry Distributed Tracing (Python)

**Pattern**: Instrument Python Flask application with OpenTelemetry for distributed tracing, exporting traces to Application Insights via OTLP endpoint.

**When to Use**: Python applications, OpenTelemetry standard (vendor-neutral), distributed tracing across microservices with W3C Trace Context propagation.

```python
# app.py
from flask import Flask, request, jsonify
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.sdk.resources import Resource
import requests
import os

# Configure OpenTelemetry with Application Insights
resource = Resource.create({
    "service.name": "inventory-service",
    "service.version": "1.0.0",
    "deployment.environment": os.getenv("ENVIRONMENT", "production")
})

trace.set_tracer_provider(TracerProvider(resource=resource))

# OTLP exporter for Application Insights (ingestion endpoint)
otlp_exporter = OTLPSpanExporter(
    endpoint=f"{os.getenv('APPLICATIONINSIGHTS_ENDPOINT')}/v1/traces",
    headers={"Authorization": f"Bearer {os.getenv('APPLICATIONINSIGHTS_CONNECTION_STRING')}"}
)

trace.get_tracer_provider().add_span_processor(BatchSpanProcessor(otlp_exporter))

app = Flask(__name__)

# Auto-instrument Flask (automatically creates spans for HTTP requests)
FlaskInstrumentor().instrument_app(app)

# Auto-instrument requests library (automatically creates spans for HTTP calls)
RequestsInstrumentor().instrument()

tracer = trace.get_tracer(__name__)

@app.route('/api/inventory/<product_id>', methods=['GET'])
def get_inventory(product_id):
    # Current span automatically created by FlaskInstrumentor
    current_span = trace.get_current_span()

    # Add custom attributes to span
    current_span.set_attribute("product.id", product_id)
    current_span.set_attribute("http.route", "/api/inventory/<product_id>")

    try:
        # Create child span for database query
        with tracer.start_as_current_span("query_database") as db_span:
            db_span.set_attribute("db.system", "postgresql")
            db_span.set_attribute("db.statement", f"SELECT * FROM inventory WHERE product_id = '{product_id}'")

            # Simulated database query
            import time
            time.sleep(0.05)  # Simulate DB latency

            quantity = 42  # Simulated result
            db_span.set_attribute("db.rows_returned", 1)

        # Create child span for external API call
        with tracer.start_as_current_span("call_pricing_service") as api_span:
            api_span.set_attribute("http.method", "GET")
            api_span.set_attribute("http.url", f"https://pricing-service.example.com/api/price/{product_id}")

            try:
                # requests library automatically creates nested span
                response = requests.get(
                    f"https://pricing-service.example.com/api/price/{product_id}",
                    timeout=5
                )
                response.raise_for_status()

                price = response.json().get("price", 0.0)

                api_span.set_attribute("http.status_code", response.status_code)
                api_span.set_attribute("pricing.price", price)

            except requests.RequestException as e:
                api_span.set_attribute("error", True)
                api_span.set_attribute("error.message", str(e))
                api_span.record_exception(e)
                raise

        # Add span event for business logic
        current_span.add_event("inventory_checked", {
            "product.id": product_id,
            "inventory.quantity": quantity
        })

        return jsonify({
            "product_id": product_id,
            "quantity": quantity,
            "price": price
        })

    except Exception as e:
        current_span.set_attribute("error", True)
        current_span.record_exception(e)
        return jsonify({"error": "Failed to retrieve inventory"}), 500

@app.route('/api/reserve', methods=['POST'])
def reserve_inventory():
    data = request.get_json()
    product_id = data.get('product_id')
    quantity = data.get('quantity')

    # Manual span creation for custom operation
    with tracer.start_as_current_span("reserve_inventory_operation") as span:
        span.set_attribute("product.id", product_id)
        span.set_attribute("inventory.quantity_requested", quantity)

        # Simulate reservation logic
        with tracer.start_as_current_span("update_database") as db_span:
            db_span.set_attribute("db.system", "postgresql")
            db_span.set_attribute("db.statement", f"UPDATE inventory SET reserved = reserved + {quantity} WHERE product_id = '{product_id}'")

            import time
            time.sleep(0.03)

            db_span.set_attribute("db.rows_affected", 1)

        span.add_event("inventory_reserved", {
            "product.id": product_id,
            "quantity": quantity,
            "reservation.id": "12345"
        })

        return jsonify({"reservation_id": "12345", "status": "reserved"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

**Explanation**: OpenTelemetry provides vendor-neutral instrumentation. `FlaskInstrumentor` automatically creates spans for HTTP requests. `RequestsInstrumentor` automatically propagates W3C Trace Context headers for distributed tracing. `tracer.start_as_current_span()` creates child spans with automatic parent-child relationships. Span attributes add context for filtering/querying in Application Insights. `span.record_exception()` captures exception details in trace. OTLP exporter sends traces to Application Insights ingestion endpoint.

---

## Example 3: Log Analytics KQL Queries for Observability

**Pattern**: Query Application Insights telemetry using Kusto Query Language (KQL) in Log Analytics for incident investigation, performance analysis, and alerting.

**When to Use**: Troubleshooting production issues, analyzing performance bottlenecks, creating dashboards, defining alert rules.

```kusto
// Query 1: Requests with slowest response times (P95 latency)
requests
| where timestamp > ago(1h)
| summarize P95Latency = percentile(duration, 95), RequestCount = count() by operation_Name
| order by P95Latency desc
| take 10

// Query 2: Failed requests with exception details
requests
| where timestamp > ago(24h)
| where success == false
| join kind=inner (
    exceptions
    | where timestamp > ago(24h)
) on operation_Id
| project timestamp, operation_Name, resultCode, client_IP,
    exceptionType = type, exceptionMessage = outerMessage,
    exceptionStack = details[0].parsedStack
| order by timestamp desc
| take 100

// Query 3: Dependency call failures (external API/database errors)
dependencies
| where timestamp > ago(1h)
| where success == false
| summarize FailureCount = count(), AvgDuration = avg(duration) by name, type, target
| order by FailureCount desc

// Query 4: Distributed trace reconstruction (follow operation_Id across services)
let operationId = "a1b2c3d4-e5f6-7890-1234-567890abcdef"; // From failed request
union requests, dependencies, traces, exceptions
| where operation_Id == operationId
| project timestamp, itemType,
    ServiceName = cloud_RoleName,
    OperationName = iff(itemType == "request", operation_Name, name),
    Duration = duration,
    Success = success,
    Details = iff(itemType == "exception", message, "")
| order by timestamp asc

// Query 5: Custom events analysis (business metrics)
customEvents
| where timestamp > ago(7d)
| where name == "OrderCreated"
| extend CustomerId = tostring(customDimensions.CustomerId),
         OrderValue = todouble(customDimensions.OrderValue)
| summarize OrderCount = count(), TotalRevenue = sum(OrderValue) by bin(timestamp, 1d)
| render timechart

// Query 6: Anomaly detection for request rates
requests
| where timestamp > ago(30d)
| summarize RequestCount = count() by bin(timestamp, 1h)
| render anomalychart with (anomalycolumns=RequestCount)

// Query 7: Performance funnel (identify slowest stage in distributed operation)
let funnelOperationId = "abc123-operation-id";
dependencies
| where operation_Id == funnelOperationId
| summarize TotalDuration = sum(duration), CallCount = count() by name
| order by TotalDuration desc

// Query 8: Alert query (failure rate exceeds threshold)
let threshold = 0.05; // 5% failure rate
requests
| where timestamp > ago(5m)
| summarize TotalRequests = count(), FailedRequests = countif(success == false)
| extend FailureRate = todouble(FailedRequests) / TotalRequests
| where FailureRate > threshold
| project FailureRate, TotalRequests, FailedRequests

// Query 9: Custom metrics aggregation
customMetrics
| where timestamp > ago(1h)
| where name == "OrderValue"
| summarize AvgOrderValue = avg(value), MaxOrderValue = max(value), P95OrderValue = percentile(value, 95)
| render timechart

// Query 10: Availability test results
availabilityResults
| where timestamp > ago(24h)
| summarize SuccessRate = 100.0 * countif(success == true) / count(),
            AvgDuration = avg(duration) by location, name
| order by SuccessRate asc
```

**Explanation**: KQL queries power Application Insights analytics, dashboards, and alerts. `operation_Id` correlates distributed traces across services. `customDimensions` accesses custom properties from telemetry initializers. `percentile()` calculates P95/P99 latencies. `join` combines telemetry types (requests + exceptions). `render timechart` visualizes metrics. `anomalychart` detects anomalies using ML. Alert rules trigger when query returns rows (e.g., failure rate > 5%).

---

## Example 4: Azure Monitor Alert Rules with Action Groups

**Pattern**: Configure metric-based and log-based alerts with Azure Monitor, triggering notifications (email, webhook, Logic Apps) via Action Groups.

**When to Use**: Proactive incident detection (high error rate, slow response times, dependency failures), automated remediation (scale-out, restart), on-call notifications.

```bicep
// infra/monitoring.bicep
param location string = resourceGroup().location
param appInsightsName string
param actionGroupName string = 'ag-critical-alerts'
param emailRecipients array = ['oncall@example.com']

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

// Action Group (notification channel)
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: 'global'
  properties: {
    groupShortName: 'Critical'
    enabled: true
    emailReceivers: [
      for email in emailRecipients: {
        name: 'EmailReceiver-${uniqueString(email)}'
        emailAddress: email
        useCommonAlertSchema: true
      }
    ]
    webhookReceivers: [
      {
        name: 'SlackWebhook'
        serviceUri: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        useCommonAlertSchema: true
      }
    ]
    azureFunctionReceivers: [
      {
        name: 'AutoRemediation'
        functionAppResourceId: '/subscriptions/.../resourceGroups/.../providers/Microsoft.Web/sites/func-auto-remediation'
        functionName: 'HandleAlert'
        httpTriggerUrl: 'https://func-auto-remediation.azurewebsites.net/api/HandleAlert'
        useCommonAlertSchema: true
      }
    ]
  }
}

// Metric Alert: High failure rate (>5% in 5 minutes)
resource failureRateAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-high-failure-rate'
  location: 'global'
  properties: {
    description: 'Alert when failure rate exceeds 5% in 5 minutes'
    severity: 1 // Critical
    enabled: true
    scopes: [appInsights.id]
    evaluationFrequency: 'PT1M' // Every 1 minute
    windowSize: 'PT5M' // 5-minute window
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'FailureRateCondition'
          metricName: 'requests/failed'
          metricNamespace: 'microsoft.insights/components'
          operator: 'GreaterThan'
          threshold: 5
          timeAggregation: 'Percent'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// Metric Alert: Slow response times (P95 > 3 seconds)
resource slowResponseAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-slow-response-times'
  location: 'global'
  properties: {
    description: 'Alert when P95 response time exceeds 3 seconds'
    severity: 2 // Warning
    enabled: true
    scopes: [appInsights.id]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'ResponseTimeCondition'
          metricName: 'requests/duration'
          metricNamespace: 'microsoft.insights/components'
          operator: 'GreaterThan'
          threshold: 3000 // 3 seconds in milliseconds
          timeAggregation: 'Percentile95'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// Log Alert: Dependency failures
resource dependencyFailureAlert 'Microsoft.Insights/scheduledQueryRules@2021-08-01' = {
  name: 'alert-dependency-failures'
  location: location
  properties: {
    description: 'Alert when dependency call failure rate exceeds 10% in 10 minutes'
    severity: 1
    enabled: true
    scopes: [appInsights.id]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT10M'
    criteria: {
      allOf: [
        {
          query: '''
            dependencies
            | where timestamp > ago(10m)
            | summarize TotalCalls = count(), FailedCalls = countif(success == false)
            | extend FailureRate = todouble(FailedCalls) / TotalCalls * 100
            | where FailureRate > 10
          '''
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [actionGroup.id]
    }
  }
}

// Log Alert: Specific exception type
resource criticalExceptionAlert 'Microsoft.Insights/scheduledQueryRules@2021-08-01' = {
  name: 'alert-critical-exception'
  location: location
  properties: {
    description: 'Alert on NullReferenceException or OutOfMemoryException'
    severity: 0 // Critical
    enabled: true
    scopes: [appInsights.id]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: '''
            exceptions
            | where timestamp > ago(5m)
            | where type in ("System.NullReferenceException", "System.OutOfMemoryException")
            | summarize ExceptionCount = count() by type, operation_Name, cloud_RoleName
          '''
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [actionGroup.id]
    }
  }
}
```

**Explanation**: Azure Monitor alerts use metric-based (requests/failed, requests/duration aggregations) or log-based (KQL queries) conditions. Action Groups define notification channels (email, webhook, Azure Functions for auto-remediation). `evaluationFrequency` controls how often alert rule runs. `windowSize` defines lookback period. `severity` ranges from 0 (critical) to 4 (informational). `useCommonAlertSchema` standardizes alert payload format. Alerts resolve automatically when condition no longer met.

---

## Example 5: Custom Metrics and Azure Monitor Workbooks

**Pattern**: Publish custom business metrics (order count, revenue, active users) to Application Insights, visualize in Azure Monitor Workbooks with interactive dashboards.

**When to Use**: Business KPI tracking (beyond technical metrics), executive dashboards, real-time operational monitoring.

```csharp
// Services/MetricsService.cs
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.Metrics;

public class MetricsService
{
    private readonly TelemetryClient _telemetryClient;
    private readonly Metric _activeUsersMetric;
    private readonly Metric _orderProcessingTimeMetric;

    public MetricsService(TelemetryClient telemetryClient)
    {
        _telemetryClient = telemetryClient;

        // Pre-aggregate metrics (more efficient than individual TrackMetric calls)
        _activeUsersMetric = _telemetryClient.GetMetric(new MetricIdentifier(
            metricNamespace: "BusinessMetrics",
            metricId: "ActiveUsers",
            dimensionName1: "Region"
        ));

        _orderProcessingTimeMetric = _telemetryClient.GetMetric(new MetricIdentifier(
            metricNamespace: "BusinessMetrics",
            metricId: "OrderProcessingTime",
            dimensionName1: "OrderType",
            dimensionName2: "Priority"
        ));
    }

    public void TrackActiveUser(string region)
    {
        _activeUsersMetric.TrackValue(1, region);
    }

    public void TrackOrderProcessingTime(double durationMs, string orderType, string priority)
    {
        _orderProcessingTimeMetric.TrackValue(durationMs, orderType, priority);
    }

    public void TrackRevenue(decimal amount, string currency, string productCategory)
    {
        _telemetryClient.TrackMetric(
            name: "Revenue",
            value: (double)amount,
            properties: new Dictionary<string, string>
            {
                { "Currency", currency },
                { "ProductCategory", productCategory }
            }
        );
    }

    public void TrackInventoryLevel(int productId, int quantity, string warehouseLocation)
    {
        _telemetryClient.TrackMetric(
            name: "InventoryLevel",
            value: quantity,
            properties: new Dictionary<string, string>
            {
                { "ProductId", productId.ToString() },
                { "WarehouseLocation", warehouseLocation }
            }
        );
    }
}
```

**Azure Monitor Workbook JSON (Excerpt)**:

```json
{
  "version": "Notebook/1.0",
  "items": [
    {
      "type": 9,
      "content": {
        "version": "KqlParameterItem/1.0",
        "parameters": [
          {
            "id": "timeRange",
            "version": "KqlParameterItem/1.0",
            "name": "TimeRange",
            "type": 4,
            "isRequired": true,
            "value": { "durationMs": 3600000 },
            "typeSettings": {
              "selectableValues": [
                {
                  "durationMs": 1800000,
                  "createdTime": "2023-01-01T00:00:00.000Z",
                  "isInitialTime": false,
                  "grain": 1,
                  "useDashboardTimeRange": false
                },
                { "durationMs": 3600000 },
                { "durationMs": 86400000 }
              ]
            }
          }
        ]
      }
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "customMetrics\n| where timestamp {TimeRange}\n| where name == \"Revenue\"\n| extend Currency = tostring(customDimensions.Currency), ProductCategory = tostring(customDimensions.ProductCategory)\n| summarize TotalRevenue = sum(value) by ProductCategory\n| render piechart",
        "size": 0,
        "title": "Revenue by Product Category",
        "queryType": 0,
        "resourceType": "microsoft.insights/components"
      }
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "customMetrics\n| where timestamp {TimeRange}\n| where namespace == \"BusinessMetrics\" and name == \"OrderProcessingTime\"\n| extend OrderType = tostring(customDimensions.OrderType)\n| summarize AvgProcessingTime = avg(value), P95ProcessingTime = percentile(value, 95) by OrderType\n| render columnchart",
        "size": 0,
        "title": "Order Processing Time (Avg vs P95)",
        "queryType": 0,
        "resourceType": "microsoft.insights/components"
      }
    }
  ]
}
```

**Explanation**: `TelemetryClient.GetMetric()` creates pre-aggregated metrics (more efficient than individual `TrackMetric` calls). Metric dimensions (Region, OrderType, Priority) enable filtering/segmentation. Azure Monitor Workbooks query custom metrics via KQL, render interactive charts (pie chart, column chart, time series). Workbooks support parameters (time range), drill-downs, and cross-resource queries.

---

## Example 6: Distributed Tracing with Correlation ID Propagation

**Pattern**: Propagate correlation ID (operation_Id) across microservices via HTTP headers (W3C Trace Context), enabling end-to-end trace reconstruction.

**When to Use**: Microservices architecture, debugging distributed transactions, performance analysis across service boundaries.

```csharp
// Service A: Order Service (initiates distributed operation)
using System.Diagnostics;
using Microsoft.ApplicationInsights;

public class OrderService
{
    private readonly HttpClient _httpClient;
    private readonly TelemetryClient _telemetryClient;

    public OrderService(IHttpClientFactory httpClientFactory, TelemetryClient telemetryClient)
    {
        _httpClient = httpClientFactory.CreateClient();
        _telemetryClient = telemetryClient;
    }

    public async Task<OrderResult> CreateOrderAsync(OrderRequest request)
    {
        // Current Activity (contains trace context)
        var activity = Activity.Current;

        _telemetryClient.TrackEvent("OrderCreationStarted", new Dictionary<string, string>
        {
            { "CustomerId", request.CustomerId },
            { "TraceId", activity?.TraceId.ToString() ?? "N/A" }
        });

        // Call Inventory Service (correlation ID automatically propagated via HTTP headers)
        var inventoryRequest = new HttpRequestMessage(HttpMethod.Post, "https://inventory-service/api/reserve")
        {
            Content = JsonContent.Create(new { ProductId = request.ProductId, Quantity = request.Quantity })
        };

        // Application Insights SDK automatically adds traceparent header (W3C Trace Context)
        var inventoryResponse = await _httpClient.SendAsync(inventoryRequest);
        inventoryResponse.EnsureSuccessStatusCode();

        // Call Payment Service
        var paymentRequest = new HttpRequestMessage(HttpMethod.Post, "https://payment-service/api/charge")
        {
            Content = JsonContent.Create(new { CustomerId = request.CustomerId, Amount = request.TotalAmount })
        };

        var paymentResponse = await _httpClient.SendAsync(paymentRequest);
        paymentResponse.EnsureSuccessStatusCode();

        _telemetryClient.TrackEvent("OrderCreated", new Dictionary<string, string>
        {
            { "OrderId", Guid.NewGuid().ToString() },
            { "TraceId", activity?.TraceId.ToString() ?? "N/A" }
        });

        return new OrderResult { OrderId = Guid.NewGuid(), Status = "Created" };
    }
}

// Service B: Inventory Service (receives correlation ID, continues trace)
using Microsoft.AspNetCore.Mvc;
using Microsoft.ApplicationInsights;

[ApiController]
[Route("api/[controller]")]
public class ReserveController : ControllerBase
{
    private readonly TelemetryClient _telemetryClient;

    public ReserveController(TelemetryClient telemetryClient)
    {
        _telemetryClient = telemetryClient;
    }

    [HttpPost]
    public IActionResult ReserveInventory([FromBody] ReserveRequest request)
    {
        // Application Insights SDK automatically extracts traceparent header, sets operation_Id
        var operationId = Activity.Current?.RootId; // Root trace ID
        var parentSpanId = Activity.Current?.ParentSpanId; // Parent span ID (from Order Service)

        _telemetryClient.TrackEvent("InventoryReservationStarted", new Dictionary<string, string>
        {
            { "ProductId", request.ProductId },
            { "Quantity", request.Quantity.ToString() },
            { "OperationId", operationId ?? "N/A" },
            { "ParentSpanId", parentSpanId?.ToString() ?? "N/A" }
        });

        // Simulate database call (automatically tracked as dependency)
        using var operation = _telemetryClient.StartOperation<Microsoft.ApplicationInsights.DataContracts.DependencyTelemetry>("UpdateInventoryDatabase");
        operation.Telemetry.Type = "SQL";
        operation.Telemetry.Data = $"UPDATE inventory SET reserved = reserved + {request.Quantity} WHERE product_id = '{request.ProductId}'";

        System.Threading.Thread.Sleep(50); // Simulate DB latency

        operation.Telemetry.Success = true;

        _telemetryClient.TrackEvent("InventoryReserved", new Dictionary<string, string>
        {
            { "ProductId", request.ProductId },
            { "ReservationId", Guid.NewGuid().ToString() }
        });

        return Ok(new { ReservationId = Guid.NewGuid(), Status = "Reserved" });
    }
}

public record ReserveRequest(string ProductId, int Quantity);
```

**W3C Trace Context HTTP Headers (Automatic)**:

```text
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
tracestate: applicationinsights=cid-v1:a1b2c3d4-e5f6-7890-1234-567890abcdef
```

**Explanation**: Application Insights SDK automatically propagates `traceparent` header (W3C Trace Context standard) when `HttpClient` makes outbound requests. Receiving service extracts `traceparent`, continues trace with same `operation_Id`. Application Map visualizes service dependencies and trace topology. Transaction diagnostics view shows end-to-end trace with all spans (Order Service → Inventory Service → Database, Payment Service → External API) correlated by operation_Id.

---

**Note**: All examples integrate with Azure Application Insights for centralized telemetry storage, querying via Log Analytics KQL, and visualization via Azure Monitor dashboards/workbooks. Adjust connection strings, endpoints, and resource names for your Azure environment.
