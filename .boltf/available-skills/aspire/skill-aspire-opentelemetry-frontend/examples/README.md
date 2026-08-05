# OpenTelemetry Frontend Examples

Complete code examples for integrating OpenTelemetry with Aspire-hosted frontend applications.

## 📁 Structure

```text
examples/
├── angular/          # Angular-specific implementation
├── react/            # React/Vite implementation
├── aspire/           # Aspire AppHost configuration
└── README.md         # This file
```

## 🅰️ Angular Examples

| File                                                                         | Description                                           | Key Concepts                                                   |
| ---------------------------------------------------------------------------- | ----------------------------------------------------- | -------------------------------------------------------------- |
| [otel-instrumentation.ts](angular/otel-instrumentation.ts)                   | OpenTelemetry provider with ZoneContextManager        | `ZoneContextManager`, `WebTracerProvider`, `OTLPTraceExporter` |
| [app.config.ts](angular/app.config.ts)                                       | Application configuration with correct provider order | Provider registration order, HTTP client setup                 |
| [trace-propagation.interceptor.ts](angular/trace-propagation.interceptor.ts) | Manual W3C Trace Context propagation                  | HTTP interceptor, `propagation.inject()`, Zone.js workaround   |
| [proxy.conf.js](angular/proxy.conf.js)                                       | Development proxy for OTLP forwarding                 | CORS bypass, OTLP HTTP endpoint                                |

### Why Angular is Special

Angular's **Zone.js** breaks OpenTelemetry's automatic trace propagation. You need:

1. **ZoneContextManager** - Maintains trace context across async operations
2. **Manual interceptor** - Explicitly injects `traceparent` headers
3. **Strict provider order** - Telemetry must initialize first

### Angular Setup Steps

1. Copy [otel-instrumentation.ts](angular/otel-instrumentation.ts) to `src/app/core/telemetry/`
2. Copy [trace-propagation.interceptor.ts](angular/trace-propagation.interceptor.ts) to `src/app/core/interceptors/`
3. Copy [proxy.conf.js](angular/proxy.conf.js) to project root
4. Update [app.config.ts](angular/app.config.ts) with correct provider order
5. Update `package.json`: `"start": "ng serve --ssl --proxy-config proxy.conf.js"`

## ⚛️ React Examples

| File                                   | Description                                         | Key Concepts                             |
| -------------------------------------- | --------------------------------------------------- | ---------------------------------------- |
| [telemetry.ts](react/telemetry.ts)     | OpenTelemetry initialization (simpler than Angular) | `WebTracerProvider`, `OTLPTraceExporter` |
| [vite.config.ts](react/vite.config.ts) | Vite proxy configuration                            | Vite dev server proxy                    |
| [main.tsx](react/main.tsx)             | App entry point with telemetry initialization       | Init order                               |

### Why React is Simpler

React **doesn't use Zone.js**, so:

- ✅ No `ZoneContextManager` needed
- ✅ No manual trace propagation interceptor
- ✅ Auto-instrumentation works out of the box
- ✅ Simpler provider configuration

### React Setup Steps

1. Copy [telemetry.ts](react/telemetry.ts) to `src/`
2. Update [main.tsx](react/main.tsx) to call `initTelemetry()` before rendering
3. Update [vite.config.ts](react/vite.config.ts) with proxy configuration

## 🚀 Aspire Configuration

| File                                              | Description                             | Key Concepts                                               |
| ------------------------------------------------- | --------------------------------------- | ---------------------------------------------------------- |
| [Program.cs](aspire/Program.cs)                   | AppHost configuration for frontend apps | `AddJavaScriptApp()`, `WithReference()`, service discovery |
| [launchSettings.json](aspire/launchSettings.json) | Environment variables for OTLP endpoint | `DOTNET_DASHBOARD_OTLP_HTTP_ENDPOINT_URL`                  |

### Aspire Setup Steps

1. Update AppHost [Program.cs](aspire/Program.cs):

   ```csharp
   var frontend = builder.AddJavaScriptApp("frontend", "../path/to/frontend")
       .WithNpm()
       .WithRunScript("start")
       .WithExternalHttpEndpoints()
       .WithReference(backendApi)
       .WaitFor(backendApi);
   ```

2. Ensure [launchSettings.json](aspire/launchSettings.json) contains:

   ```json
   "DOTNET_DASHBOARD_OTLP_HTTP_ENDPOINT_URL": "http://localhost:18889"
   ```

## 📦 Required Dependencies

### Angular

```bash
npm install @opentelemetry/sdk-trace-web \
            @opentelemetry/instrumentation \
            @opentelemetry/auto-instrumentations-web \
            @opentelemetry/context-zone \
            @opentelemetry/core \
            @opentelemetry/exporter-trace-otlp-http \
            @opentelemetry/resources \
            @opentelemetry/semantic-conventions
```

### React

```bash
npm install @opentelemetry/sdk-trace-web \
            @opentelemetry/instrumentation \
            @opentelemetry/auto-instrumentations-web \
            @opentelemetry/core \
            @opentelemetry/exporter-trace-otlp-http \
            @opentelemetry/resources \
            @opentelemetry/semantic-conventions
```

## 🔍 Quick Comparison

| Aspect            | Angular                       | React                         |
| ----------------- | ----------------------------- | ----------------------------- |
| Context Manager   | `ZoneContextManager` required | Default context manager works |
| Trace Propagation | Manual interceptor required   | Auto-instrumentation works    |
| Setup Complexity  | High (Zone.js considerations) | Low (standard setup)          |
| Provider Order    | Critical                      | Less critical                 |
| Lines of Code     | ~150                          | ~80                           |

## 🎯 Common Patterns

### OTLP Endpoint Configuration

Both frameworks read endpoint from environment variable:

```javascript
const otlpEndpoint =
  process.env.DOTNET_DASHBOARD_OTLP_HTTP_ENDPOINT_URL || 'http://localhost:18889';
```

### Relative Path for Traces

Always use relative path (not absolute URL) to avoid CORS:

```typescript
const exporter = new OTLPTraceExporter({
  url: '/v1/traces', // ✅ Relative - goes through proxy
  // url: 'http://localhost:18889/v1/traces', // ❌ Absolute - CORS errors
});
```

### Service Name Configuration

Set service name in resource attributes:

```typescript
resource: new Resource({
  [ATTR_SERVICE_NAME]: 'frontend',
});
```

## 📚 Additional Resources

- [OpenTelemetry JavaScript Documentation](https://opentelemetry.io/docs/instrumentation/js/)
- [Aspire Dashboard Documentation](https://learn.microsoft.com/dotnet/aspire/fundamentals/dashboard/)
- [W3C Trace Context Specification](https://www.w3.org/TR/trace-context/)
- [Angular Zone.js Documentation](https://angular.dev/guide/zonejs)

## ❓ Need Help?

Refer to the main [SKILL.md](../SKILL.md) for:

- When to use this skill
- Validation procedures with Aspire MCP tools
- Common issues and troubleshooting
- Critical configuration points
