---
name: skill-aspire-opentelemetry-frontend
description: OpenTelemetry instrumentation for frontend apps (Angular/React/Vue) with .NET Aspire dashboard integration for distributed tracing. Use when adding telemetry to frontend, instrumenting browser apps, or connecting frontend traces to Aspire dashboard. Triggers => "OpenTelemetry frontend", "Aspire dashboard frontend", "frontend tracing", "instrument Angular", "instrument React", "browser telemetry", "E2E observability", "distributed tracing frontend", "OTLP browser".
---

# Aspire OpenTelemetry Frontend Instrumentation

Enable distributed tracing from browser-based frontends to .NET Aspire dashboard for E2E observability.

## When to Use

- Frontend app (Angular/React) with .NET Aspire backend
- Need browser → backend distributed tracing visible in Aspire dashboard
- Troubleshooting performance issues end-to-end
- Want to correlate user interactions with backend operations

## When NOT to Use

- Backend-only applications (Aspire handles this automatically)
- Static sites without API calls
- Non-Aspire backend (use standard OpenTelemetry setup)

## Quick Start

### Angular

```bash
# 1. Install OpenTelemetry packages
npm install @opentelemetry/api @opentelemetry/auto-instrumentations-web \
  @opentelemetry/context-zone @opentelemetry/exporter-trace-otlp-proto \
  @opentelemetry/resources @opentelemetry/sdk-trace-web @opentelemetry/semantic-conventions

# 2. Create instrumentation provider (src/app/core/services/otel-instrumentation.ts)
# 3. Create trace propagation interceptor (src/app/core/interceptors/trace-propagation.interceptor.ts)
# 4. Configure proxy (proxy.conf.js) to forward /v1/traces
# 5. Update app.config.ts providers
```

### React/Vite

```bash
# 1. Install same OpenTelemetry packages
# 2. Create src/telemetry.ts with initializeTelemetry()
# 3. Configure vite.config.ts proxy
# 4. Initialize in main.tsx before render
```

## Key Actions

### 1. Initialize OpenTelemetry Provider (Angular)

**Angular requires special configuration due to Zone.js:**

- **Instrumentation Provider**: See [examples/angular/otel-instrumentation.ts](examples/angular/otel-instrumentation.ts)
  - Uses `ZoneContextManager` (CRITICAL for Angular)
  - Configures `WebTracerProvider` with OTLP exporter
  - Registers auto-instrumentations

- **Application Configuration**: See [examples/angular/app.config.ts](examples/angular/app.config.ts)
  - `provideInstrumentation()` MUST be first provider
  - HTTP client must include trace propagation interceptor as first interceptor

**Key requirement**: Provider registration order is critical for trace context propagation.

### 2. Manual Trace Propagation (Angular)

**Why needed**: Angular Zone.js breaks OpenTelemetry auto-instrumentation of `traceparent` headers.

**Implementation**: See [examples/angular/trace-propagation.interceptor.ts](examples/angular/trace-propagation.interceptor.ts)

This interceptor:

- Extracts active OpenTelemetry span from context
- Injects W3C Trace Context headers (`traceparent`, `tracestate`)
- MUST be registered FIRST in HTTP interceptor chain

**React/Vite**: No manual interceptor needed - auto-instrumentation works. See [examples/react/telemetry.ts](examples/react/telemetry.ts)

### 3. Configure Proxy for OTLP Forwarding

**Purpose**: Forward browser traces to Aspire Dashboard's OTLP collector (browsers can't send directly due to CORS).

**Angular**: See [examples/angular/proxy.conf.js](examples/angular/proxy.conf.js)

- Reads endpoint from `DOTNET_DASHBOARD_OTLP_HTTP_ENDPOINT_URL`
- Forwards `/v1/traces` to OTLP HTTP endpoint (port 18889)
- Start script: `"start": "ng serve --ssl --proxy-config proxy.conf.js"`

**React/Vite**: See [examples/react/vite.config.ts](examples/react/vite.config.ts)

- Same concept, Vite-specific configuration
- Entry point initialization: [examples/react/main.tsx](examples/react/main.tsx)

**Critical**: Use relative path `/v1/traces` (not absolute URL) to avoid CORS errors.

### 4. Configure Aspire AppHost

**AppHost Configuration**: See [examples/aspire/Program.cs](examples/aspire/Program.cs)

Key features:

- `AddJavaScriptApp()` registers frontend with Aspire
- `WithReference(backendApi)` enables service discovery (injects environment variables)
- `WaitFor(backendApi)` ensures backend starts first

**Environment Variables**: See [examples/aspire/launchSettings.json](examples/aspire/launchSettings.json)

Must include:

- `DOTNET_DASHBOARD_OTLP_HTTP_ENDPOINT_URL`: OTLP collector endpoint
- `ASPIRE_ALLOW_UNSECURED_TRANSPORT`: Enable HTTP (development)
- `DASHBOARD__OTLP__AUTHMODE`: Unsecured for local development

## 📁 Complete Code Examples

All implementation files are available in the [examples/](examples/) directory:

- **Angular**: [examples/angular/](examples/angular/) - Full instrumentation with Zone.js workarounds
- **React**: [examples/react/](examples/react/) - Simpler setup without Zone.js complexity
- **Aspire**: [examples/aspire/](examples/aspire/) - AppHost and launch settings configuration
- **Index**: [examples/README.md](examples/README.md) - Navigation and detailed setup instructions

## Critical Configuration Points

**ZoneContextManager**: Required for Angular to maintain trace context across async operations.

**Interceptor Order**: tracePropagationInterceptor MUST be first to inject traceparent before auth/tenant headers.

**Proxy Path**: Use relative path `/v1/traces` (same-origin) not absolute URL (CORS).

**OTLP/HTTP**: Use HTTP endpoint (18889), NOT gRPC (4317) - browsers don't support gRPC.

**Dynamic Ports**: Read `DOTNET_DASHBOARD_OTLP_HTTP_ENDPOINT_URL` from environment, don't hardcode.

## Verification

1. **Browser console**: Look for "[Telemetry] ✅ OpenTelemetry initialization complete"
2. **Network tab**: Verify `traceparent` header in API requests
3. **Aspire dashboard**: Navigate to Traces → Filter by service "frontend"
4. **Distributed context**: Click trace to see browser → backend → database linked spans

## Common Issues

**Traces not appearing**: Check proxy endpoint matches `DOTNET_DASHBOARD_OTLP_HTTP_ENDPOINT_URL`

**CORS errors**: Ensure using relative path `/v1/traces` not absolute URL

**traceparent missing**: Verify tracePropagationInterceptor is FIRST in chain

**Zone.js errors**: Ensure using `ZoneContextManager` in provider registration

## Validation with Aspire MCP Tools

Aspire provides MCP (Model Context Protocol) tools to validate your OpenTelemetry setup is working correctly. Use these tools through GitHub Copilot to inspect resources, logs, and traces.

### 1. Verify Resources Are Running

**Tool**: `mcp_aspire_list_resources`

**Purpose**: Check if frontend and backend resources are running with correct health status.

**What to verify**:

- Frontend resource shows "Running" state
- HTTPS endpoint is exposed (typically <https://localhost:5001>)
- Backend APIs are also running
- All health checks pass

**Example response**:

```json
{
  "name": "frontend",
  "resourceType": "Executable",
  "state": "Running",
  "endpoints": [
    {
      "endpointUrl": "https://localhost:5001",
      "proxyUrl": "https://localhost:7095"
    }
  ],
  "healthStatus": "Healthy"
}
```

**Troubleshooting**:

- If state is "FailedToStart": Check console logs (see next step)
- If healthStatus is "Unhealthy": Review resource configuration
- If endpoints missing: Verify `WithExternalHttpEndpoints()` in AppHost

### 2. Check Frontend Console Logs

**Tool**: `mcp_aspire_list_console_logs`

**Purpose**: View frontend startup logs to verify OpenTelemetry initialization.

**What to look for**:

```text
[Telemetry] ✅ OpenTelemetry initialization complete
✅ Connected to OTLP endpoint: http://localhost:18889/v1/traces
```

**Command example** (via Copilot):

> "Show me console logs for the frontend resource"

**Troubleshooting**:

- **Error: "Failed to connect to OTLP endpoint"**: Verify proxy configuration matches `DOTNET_DASHBOARD_OTLP_HTTP_ENDPOINT_URL`
- **Error: "ZoneContextManager not found"**: Missing `@opentelemetry/context-zone` dependency
- **No telemetry logs**: Check provider registration in `app.config.ts`

### 3. Verify Trace Propagation

**Tool**: `mcp_aspire_list_traces`

**Purpose**: Confirm traces from frontend are appearing in Aspire dashboard with correct service name.

**What to verify**:

- Traces appear with service name "frontend"
- Spans show HTTP requests to backend APIs
- `traceparent` headers are present in spans
- Distributed context links frontend → backend spans

**Command example** (via Copilot):

> "Show me recent traces from the frontend service"

**What a valid trace looks like**:

```json
{
  "traceId": "abc123...",
  "spans": [
    {
      "name": "HTTP GET /api/users",
      "serviceName": "frontend",
      "attributes": {
        "http.method": "GET",
        "http.url": "https://localhost:7001/api/users",
        "traceparent": "00-abc123...-def456...-01"
      }
    }
  ]
}
```

**Troubleshooting**:

- **No traces for "frontend"**: Check OTLP exporter URL in instrumentation provider
- **Traces without traceparent**: Verify `tracePropagationInterceptor` is FIRST in Angular interceptor chain
- **Disconnected frontend/backend spans**: Context propagation broken - review interceptor implementation

### 4. Deep Dive Into Specific Trace

**Tool**: `mcp_aspire_list_trace_structured_logs`

**Purpose**: Get detailed logs associated with a specific trace ID to correlate user actions with backend operations.

**When to use**:

- Investigating slow user interactions
- Debugging failed API calls
- Understanding E2E request flow

**Command example** (via Copilot):

> "Show me structured logs for trace ID abc123..."

**What you'll see**:

- Frontend: User clicked button → HTTP request initiated
- Backend: Request received → Database query → Response sent
- Full distributed trace with timing information

### 5. Restart Resources if Needed

**Tool**: `mcp_aspire_execute_resource_command`

**Purpose**: Restart frontend or backend resources without restarting entire Aspire dashboard.

**Common scenarios**:

- Applied configuration changes (proxy, environment variables)
- Installed new OpenTelemetry dependencies
- Modified instrumentation code

**Command example** (via Copilot):

> "Restart the frontend resource"

**Parameters**:

- `resourceName`: "frontend"
- `commandType`: "Restart"

### Validation Checklist

Use Aspire MCP tools to verify each step:

- [ ] **Resources**: `mcp_aspire_list_resources` shows frontend as "Running" with HTTPS endpoint
- [ ] **Console Logs**: `mcp_aspire_list_console_logs` shows "[Telemetry] ✅ OpenTelemetry initialization complete"
- [ ] **Traces**: `mcp_aspire_list_traces` returns traces with service name "frontend"
- [ ] **Trace Content**: Spans include `traceparent` headers and HTTP attributes
- [ ] **Distributed Context**: Frontend spans link to backend spans (same traceId)
- [ ] **No Errors**: Console logs show no CORS errors or OTLP connection failures

### Quick Validation Workflow

1. **Start Aspire AppHost** → Run AppHost project
2. **Check Resource Health** → Use `mcp_aspire_list_resources`
3. **View Startup Logs** → Use `mcp_aspire_list_console_logs` for "frontend"
4. **Trigger User Action** → Navigate frontend, click buttons, make API calls
5. **Verify Traces** → Use `mcp_aspire_list_traces` to confirm distributed tracing
6. **Inspect Trace Details** → Use `mcp_aspire_list_trace_structured_logs` for specific trace

**Pro tip**: Use GitHub Copilot natural language commands to invoke these tools:

- "Are all my Aspire resources healthy?"
- "Show me the latest frontend traces"
- "Why is my frontend failing to start?"

## References

- [OpenTelemetry JavaScript](https://opentelemetry.io/docs/instrumentation/js/)
- [Aspire with Angular Example](https://github.com/robertomenciasoftwareone/AspireWithAngular)
- [W3C Trace Context](https://www.w3.org/TR/trace-context/)
- [Aspire Dashboard OTLP](https://learn.microsoft.com/dotnet/aspire/fundamentals/dashboard/standalone)
