/**
 * Vite Configuration with OTLP Proxy
 *
 * Forwards OTLP traces from browser to Aspire Dashboard's OTLP collector.
 * Same concept as Angular proxy.conf.js but for Vite dev server.
 */

import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

const otlpEndpoint =
  process.env.DOTNET_DASHBOARD_OTLP_HTTP_ENDPOINT_URL || 'http://localhost:18889';

export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/v1/traces': {
        target: otlpEndpoint,
        changeOrigin: true,
        secure: false,
      },
    },
  },
});
