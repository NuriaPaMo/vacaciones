import { FullConfig } from "@playwright/test";

/**
 * Global setup OPCIONAL para Playwright con Aspire
 *
 * IMPORTANTE: Este archivo es OPCIONAL. El agente/runner que ejecuta los tests
 * debe verificar que Aspire está listo ANTES de llamar a Playwright.
 *
 * Este global-setup solo sirve como validación adicional de seguridad,
 * pero NO debe ser la única verificación de disponibilidad de servicios.
 */
async function globalSetup(config: FullConfig) {
  console.log("✅ Playwright global setup - Aspire should already be ready");

  // Opcional: Verificación rápida de sanity check
  // El runner ya debería haber verificado que todo está listo
  const baseURL = config.use?.baseURL || "http://localhost:4200";
  console.log(`📍 Base URL: ${baseURL}`);
}

export default globalSetup;
