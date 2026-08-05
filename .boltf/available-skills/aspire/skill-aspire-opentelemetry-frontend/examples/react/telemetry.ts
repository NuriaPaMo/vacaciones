/**
 * OpenTelemetry Instrumentation for React/Vite
 *
 * Initialize this module BEFORE rendering your React app.
 * Call initTelemetry() in main.tsx before ReactDOM.createRoot().
 *
 * Key differences from Angular:
 * - No ZoneContextManager needed (React doesn't use Zone.js)
 * - No manual trace propagation interceptor (auto-instrumentation works)
 * - Simpler setup overall
 */

import { getWebAutoInstrumentations } from '@opentelemetry/auto-instrumentations-web';
import { W3CTraceContextPropagator } from '@opentelemetry/core';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { registerInstrumentations } from '@opentelemetry/instrumentation';
import { Resource } from '@opentelemetry/resources';
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-base';
import { WebTracerProvider } from '@opentelemetry/sdk-trace-web';
import { ATTR_SERVICE_NAME } from '@opentelemetry/semantic-conventions';

export function initTelemetry() {
  const provider = new WebTracerProvider({
    resource: new Resource({
      [ATTR_SERVICE_NAME]: 'frontend',
    }),
  });

  // Configure OTLP exporter to send traces via Vite proxy
  const exporter = new OTLPTraceExporter({
    url: '/v1/traces', // Relative path - goes through Vite proxy to Aspire dashboard
  });

  provider.addSpanProcessor(new BatchSpanProcessor(exporter));

  provider.register({
    propagator: new W3CTraceContextPropagator(),
  });

  registerInstrumentations({
    tracerProvider: provider,
    instrumentations: [
      getWebAutoInstrumentations({
        '@opentelemetry/instrumentation-fetch': {
          propagateTraceHeaderCorsUrls: /.*/,
          clearTimingResources: true,
        },
        '@opentelemetry/instrumentation-xml-http-request': {
          propagateTraceHeaderCorsUrls: /.*/,
        },
      }),
    ],
  });

  console.log('[Telemetry] ✅ OpenTelemetry initialization complete');
}
