import { defineConfig } from "@playwright/test";

/**
 * Playwright configuration for Aspire-managed services
 *
 * Key differences from standalone config:
 * - No webServer config (Aspire manages service lifecycle)
 * - Longer timeouts for distributed services
 * - NO global setup to wait for services (the runner handles that)
 *
 * IMPORTANTE: El agente/runner debe iniciar Aspire y verificar que los servicios
 * están listos ANTES de ejecutar 'npx playwright test'.
 */
export default defineConfig({
  testDir: "./tests/e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,

  reporter: [
    ["html"],
    ["junit", { outputFile: "test-results/junit.xml" }],
    ["json", { outputFile: "test-results/results.json" }],
  ],

  use: {
    // URL del frontend servido por Aspire
    baseURL: process.env.FRONTEND_URL || "http://localhost:4200",

    // Timeouts más largos para servicios distribuidos
    actionTimeout: 15000,
    navigationTimeout: 30000,

    trace: "on-first-retry",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
  },

  projects: [
    {
      name: "chromium",
      use: { browserName: "chromium" },
    },
  ],

  // NO configurar webServer - Aspire ya gestiona todos los servicios
  // NO configurar globalSetup - El runner debe verificar servicios antes de ejecutar Playwright
});
