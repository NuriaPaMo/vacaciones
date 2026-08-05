/**
 * OpenTelemetry Instrumentation Provider for Angular
 *
 * CRITICAL: This provider MUST be registered FIRST in app.config.ts
 * to ensure telemetry is initialized before other Angular components.
 *
 * Key requirements:
 * - Use ZoneContextManager for Angular Zone.js compatibility
 * - Register before HTTP client and other providers
 * - Configure W3C Trace Context propagation
 */

import { provideAppInitializer } from '@angular/core';
import { getWebAutoInstrumentations } from '@opentelemetry/auto-instrumentations-web';
import { ZoneContextManager } from '@opentelemetry/context-zone';
import { W3CTraceContextPropagator } from '@opentelemetry/core';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { registerInstrumentations } from '@opentelemetry/instrumentation';
import { Resource } from '@opentelemetry/resources';
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-base';
import { WebTracerProvider } from '@opentelemetry/sdk-trace-web';
import { ATTR_SERVICE_NAME } from '@opentelemetry/semantic-conventions';

export function provideInstrumentation() {
  return provideAppInitializer(() => {
    const provider = new WebTracerProvider({
      resource: new Resource({
        [ATTR_SERVICE_NAME]: 'frontend',
      }),
    });

    // Configure OTLP exporter to send traces via proxy
    const exporter = new OTLPTraceExporter({
      url: '/v1/traces', // Relative path - goes through proxy to Aspire dashboard
    });

    provider.addSpanProcessor(new BatchSpanProcessor(exporter));

    provider.register({
      contextManager: new ZoneContextManager(), // CRITICAL for Angular
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
  });
}
