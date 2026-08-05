// Pseudocódigo - Verificación de servicios en el RUNNER usando herramientas MCP de Aspire
//
// IMPORTANTE: Esta verificación debe ser realizada por el RUNNER/AGENTE que coordina
// la ejecución de tests E2E, NO por Playwright.
//
// El runner debe:
// 1. Iniciar Aspire
// 2. Ejecutar esta verificación usando las herramientas MCP de Aspire
// 3. SOLO cuando todos los servicios estén listos, ejecutar 'npx playwright test'
//
// Playwright NO debe tener lógica de espera de Aspire.

await aspire.waitForServices({
  services: [
    { name: "frontend", type: "angular", port: 4200 },
    { name: "auth-api", type: "webapi", port: 5001 },
    { name: "database", type: "sqlserver", port: 1433 },
  ],
  timeout: 120000, // 2 minutos
});
