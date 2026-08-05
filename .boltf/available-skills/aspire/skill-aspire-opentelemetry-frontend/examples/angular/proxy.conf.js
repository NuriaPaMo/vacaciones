/**
 * Angular Development Proxy Configuration
 *
 * Forwards OTLP traces from browser to Aspire Dashboard's OTLP collector.
 *
 * WHY PROXY IS NEEDED:
 * - Browsers cannot send traces directly to OTLP collector (CORS restrictions)
 * - Aspire exposes OTLP HTTP endpoint (typically on port 18889)
 * - Proxy forwards /v1/traces requests to collector, maintaining same-origin
 *
 * IMPORTANT:
 * - Endpoint URL is read from environment variable (set by Aspire AppHost)
 * - Use HTTP endpoint (18889), NOT gRPC (4317) - browsers don't support gRPC
 * - Update package.json: "start": "ng serve --ssl --proxy-config proxy.conf.js"
 */

const otlpEndpoint =
  process.env.DOTNET_DASHBOARD_OTLP_HTTP_ENDPOINT_URL || 'http://localhost:18889';

module.exports = {
  '/v1/traces': {
    target: otlpEndpoint,
    secure: false,
    changeOrigin: true,
    logLevel: 'debug',
  },
};
