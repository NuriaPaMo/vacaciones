/**
 * Trace Propagation HTTP Interceptor for Angular
 *
 * WHY THIS IS NEEDED:
 * Angular's Zone.js breaks OpenTelemetry's automatic traceparent header injection.
 * This interceptor manually propagates W3C Trace Context to maintain distributed tracing.
 *
 * CRITICAL: This interceptor MUST be registered FIRST in the HTTP client interceptor chain
 * to ensure traceparent/tracestate headers are injected before authentication or other headers.
 *
 * @see https://www.w3.org/TR/trace-context/
 */

import { HttpInterceptorFn } from '@angular/common/http';
import { context, propagation, trace } from '@opentelemetry/api';

export const tracePropagationInterceptor: HttpInterceptorFn = (req, next) => {
  // Get the current active OpenTelemetry context
  const activeContext = context.active();
  const currentSpan = trace.getSpan(activeContext);

  if (currentSpan) {
    // Create carrier object to hold propagated headers
    const carrier: Record<string, string> = {};

    // Inject trace context into carrier (adds traceparent, tracestate)
    propagation.inject(activeContext, carrier);

    // Clone request and add trace headers
    let modifiedReq = req;
    Object.entries(carrier).forEach(([key, value]) => {
      modifiedReq = modifiedReq.clone({
        setHeaders: { [key]: value }
      });
    });

    console.log('[Trace Propagation] Injected headers:', carrier);
    return next(modifiedReq);
  }

  // No active span - pass through unchanged
  return next(req);
};
