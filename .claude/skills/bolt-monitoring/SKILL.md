---
name: bolt-monitoring
description: "Built-in observability, performance monitoring and proactive alerting for Bolt Framework projects. Prometheus + Grafana + Loki + Jaeger stack (or Azure Monitor / CloudWatch / GCP Monitoring), auto-instrumentation per stack, constitution-based alerts, SLO/SLI tracking, RUM and synthetic monitoring. Triggers: 'monitoring', 'observability', 'Prometheus', 'Grafana', 'dashboards', 'alerts', 'SLO', 'APM', 'health checks', '/bolt-monitoring'."
---

# Bolt Monitoring — Methodology

Implement comprehensive observability, create intelligent dashboards and
proactive alerting for Bolt Framework projects.

## Stack components

### Core technologies

- **Prometheus** — metrics collection and storage.
- **Grafana** — visualization and dashboards.
- **Loki** — log aggregation and analysis.
- **Jaeger** — distributed tracing.
- **AlertManager** — alert routing and management.

### Cloud-native alternatives

- **Azure Monitor** — Application Insights integration.
- **AWS CloudWatch** — metrics and logs.
- **Google Cloud Monitoring** — Stackdriver.

## Setup commands

```bash
# Install complete monitoring stack
./.boltf/scripts/bash/setup-monitoring.sh --stack prometheus-grafana --env production

# Setup with SLO-based alerting
./.boltf/scripts/bash/setup-monitoring.sh --slo-file specs/slos.yml

# Configure cloud monitoring
./.boltf/scripts/bash/setup-cloud-monitoring.sh --provider azure --resource-group boltf-rg

# Generate dashboards based on tech stack
./.boltf/scripts/bash/generate-dashboards.sh --from-constitution

# Create custom dashboard for feature
./.boltf/scripts/bash/create-dashboard.sh --feature F001-authentication --metrics auth_requests,auth_failures

# Import community dashboards
./.boltf/scripts/bash/import-dashboards.sh --source grafana-community

# Generate SLI tracking code
./.boltf/scripts/bash/generate-sli-metrics.sh --slo-file specs/slos.yml

# Generate synthetic tests
./.boltf/scripts/bash/generate-synthetic-tests.sh --endpoints api/health,api/status

# Setup uptime monitoring
./.boltf/scripts/bash/setup-uptime-monitoring.sh --urls https://app,https://api
```

## Auto-instrumentation by tech stack

### .NET applications

```csharp
// Program.cs
builder.Services.AddApplicationInsightsTelemetry();

builder.Services.AddHealthChecks()
    .AddDbContext<AppDbContext>()
    .AddUrlGroup(new Uri("https://api.external.com/health"), "external-api");

builder.Services.AddSingleton<IMetrics, MetricsService>();

app.UseMiddleware<RequestLoggingMiddleware>();
app.UseMiddleware<ErrorTrackingMiddleware>();

app.MapHealthChecks("/health", new HealthCheckOptions
{
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse
});

app.MapPrometheusScrapingEndpoint();
```

### React applications

```typescript
import { ApplicationInsights } from '@microsoft/applicationinsights-web';
import { ReactPlugin } from '@microsoft/applicationinsights-react-js';

const reactPlugin = new ReactPlugin();
const appInsights = new ApplicationInsights({
  config: {
    instrumentationKey: process.env.VITE_APP_INSIGHTS_KEY,
    extensions: [reactPlugin],
    extensionConfig: { [reactPlugin.identifier]: { history: router } },
  },
});

export const trackPageView = (name: string, uri?: string) =>
  appInsights.trackPageView({ name, uri });

export const trackException = (exception: Error, severityLevel?: number) =>
  appInsights.trackException({ exception, severityLevel });

export const trackMetric = (name: string, average: number, properties?: any) =>
  appInsights.trackMetric({ name, average }, properties);
```

## Monitoring configuration templates

### Docker Compose stack

```yaml
# monitoring/docker-compose.monitoring.yml
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    ports: ['9090:9090']
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./prometheus/alerts.yml:/etc/prometheus/alerts.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.enable-lifecycle'
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    ports: ['3000:3000']
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/dashboards:/var/lib/grafana/dashboards
      - ./grafana/provisioning:/etc/grafana/provisioning
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=myapp2024
      - GF_USERS_ALLOW_SIGN_UP=false
    restart: unless-stopped

  loki:
    image: grafana/loki:latest
    ports: ['3100:3100']
    volumes:
      - ./loki/loki-config.yml:/etc/loki/local-config.yaml
      - loki_data:/loki
    command: -config.file=/etc/loki/local-config.yaml
    restart: unless-stopped

  promtail:
    image: grafana/promtail:latest
    volumes:
      - ./promtail/promtail-config.yml:/etc/promtail/config.yml
      - /var/log:/var/log:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
    command: -config.file=/etc/promtail/config.yml
    restart: unless-stopped

  jaeger:
    image: jaegertracing/all-in-one:latest
    ports: ['16686:16686', '14268:14268']
    environment: [COLLECTOR_OTLP_ENABLED=true]
    restart: unless-stopped

volumes:
  prometheus_data:
  grafana_data:
  loki_data:
```

### Prometheus config

```yaml
# monitoring/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - 'alerts.yml'

alerting:
  alertmanagers:
    - static_configs:
        - targets: [alertmanager:9093]

scrape_configs:
  - job_name: 'prometheus'
    static_configs: [{ targets: ['localhost:9090'] }]

  - job_name: 'myapp-api'
    static_configs: [{ targets: ['host.docker.internal:5000'] }]
    metrics_path: /metrics
    scrape_interval: 10s

  - job_name: 'myapp-frontend'
    static_configs: [{ targets: ['host.docker.internal:3000'] }]
    metrics_path: /metrics
    scrape_interval: 30s

  - job_name: 'node-exporter'
    static_configs: [{ targets: ['host.docker.internal:9100'] }]
```

## Constitution-based alerts

```yaml
# monitoring/prometheus/alerts.yml
groups:
  - name: myapp-sla-alerts
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 2m
        labels: { severity: critical, team: myapp }
        annotations:
          summary: High error rate detected
          description: 'Error rate is {{ $value | humanizePercentage }} over the last 5 minutes'

      - alert: HighResponseTime
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 0.5
        for: 5m
        labels: { severity: warning }
        annotations:
          summary: High response time
          description: '95th percentile response time is {{ $value }}s'

      - alert: LowTestCoverage
        expr: test_coverage_percentage < 80
        for: 0m
        labels: { severity: warning }
        annotations:
          summary: Test coverage below constitution threshold
          description: 'Test coverage is {{ $value }}% (constitution requires: 80%)'

      - alert: ConstitutionViolation
        expr: constitution_compliance_score < 0.9
        for: 0m
        labels: { severity: critical }
        annotations:
          summary: Constitution compliance violation detected
          description: 'Constitution compliance score: {{ $value }}'

      - alert: DatabaseConnectionFailure
        expr: up{job="myapp-api"} == 0
        for: 1m
        labels: { severity: critical }
        annotations:
          summary: Database connection lost
```

## Dashboards (Grafana JSON skeletons)

### Application overview

```json
{
  "dashboard": {
    "title": "MyApp Application Overview",
    "panels": [
      { "title": "Request Rate", "type": "graph", "targets": [{ "expr": "rate(http_requests_total[5m])" }] },
      { "title": "Response Time P95", "type": "graph", "targets": [{ "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))" }] },
      { "title": "Error Rate", "type": "singlestat", "targets": [{ "expr": "rate(http_requests_total{status=~\"5..\"}[5m]) / rate(http_requests_total[5m])" }] },
      { "title": "Active Users", "type": "singlestat", "targets": [{ "expr": "myapp_active_users_total" }] }
    ]
  }
}
```

### Business metrics

```json
{
  "dashboard": {
    "title": "MyApp Business Metrics",
    "panels": [
      { "title": "Feature Usage", "type": "table", "targets": [{ "expr": "topk(10, myapp_feature_usage_total)" }] },
      { "title": "User Journey Completion", "type": "graph", "targets": [{ "expr": "myapp_user_journey_completion_rate" }] },
      { "title": "Revenue Impact", "type": "singlestat", "targets": [{ "expr": "myapp_revenue_generated_total" }] }
    ]
  }
}
```

## SLO / SLI management

### SLO file (`specs/slos.yml`)

```yaml
slos:
  availability:
    target: 99.9%
    window: 30d
    error_budget: 0.1%
  latency:
    target: 95%
    threshold: 500ms
    window: 7d
  throughput:
    target: 1000
    unit: requests/minute
    window: 1h

features:
  authentication:
    availability: 99.95%
    latency_p99: 200ms
  checkout:
    availability: 99.99%
    latency_p95: 1s
    success_rate: 99.9%
```

## Structured logging + correlation

### .NET (Serilog + App Insights)

```csharp
builder.Services.AddLogging(config =>
{
    config.AddConsole();
    config.AddApplicationInsights();
    config.AddSerilog(new LoggerConfiguration()
        .WriteTo.Console(new JsonFormatter())
        .WriteTo.File("logs/myapp-.log", rollingInterval: RollingInterval.Day)
        .CreateLogger());
});
```

### Frontend log correlation

```typescript
const correlationId = crypto.randomUUID();
axios.defaults.headers.common['X-Correlation-ID'] = correlationId;

logger.error('Payment failed', { correlationId, userId, amount, error: error.message });
```

## RUM (web vitals)

```typescript
import { getCLS, getFID, getFCP, getLCP, getTTFB } from 'web-vitals';

function sendToAnalytics(metric) {
  fetch('/api/analytics', {
    method: 'POST',
    body: JSON.stringify(metric),
    headers: { 'Content-Type': 'application/json' },
  });
}

getCLS(sendToAnalytics);
getFID(sendToAnalytics);
getFCP(sendToAnalytics);
getLCP(sendToAnalytics);
getTTFB(sendToAnalytics);
```

## APM setup commands

```bash
./.boltf/scripts/bash/setup-apm.sh --stack dotnet --provider elastic-apm
./.boltf/scripts/bash/setup-apm.sh --stack react --provider sentry
```

## Quality gates

- Health check endpoint exposed and Prometheus scraped.
- All constitution SLAs have a corresponding alert rule.
- Each feature has at least one dashboard panel.
- SLOs documented in `specs/slos.yml`.
- Correlation IDs threaded end-to-end.

## Integration with Bolt Framework ecosystem

- **bolt-cicd**: monitor deployment success rates, performance regression
  per release.
- **bolt-testing**: correlate test coverage with production errors;
  monitor feature flag effectiveness.
- **bolt-docs**: auto-update runbooks with monitoring data; generate
  performance reports; create incident response docs.

## Related agents (next steps)

- → `bolt-cicd`: configure alerting rules and notification channels.
- → `bolt-docs`: document monitoring setup and dashboard usage.
- → `bolt-ops`: integrate monitoring into runbooks.
- → `bolt-postmortem`: feed incident metrics to postmortems.
