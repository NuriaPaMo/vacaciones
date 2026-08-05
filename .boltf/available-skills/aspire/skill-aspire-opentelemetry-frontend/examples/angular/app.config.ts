/**
 * Angular Application Configuration
 *
 * CRITICAL ORDER:
 * 1. provideInstrumentation() - MUST be first
 * 2. provideHttpClient with tracePropagationInterceptor first
 * 3. Other providers
 */

import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { ApplicationConfig, provideZoneChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';

import { routes } from './app.routes';
import { tracePropagationInterceptor } from './core/interceptors/trace-propagation.interceptor';
import { provideInstrumentation } from './core/telemetry/otel-instrumentation';

export const appConfig: ApplicationConfig = {
  providers: [
    // 1. OpenTelemetry MUST be initialized first
    provideInstrumentation(),

    // 2. HTTP client with trace propagation interceptor as FIRST interceptor
    provideHttpClient(
      withInterceptors([
        tracePropagationInterceptor, // MUST be first
        // ... other interceptors (auth, tenant, etc.)
      ])
    ),

    // 3. Other providers
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes),
  ],
};
