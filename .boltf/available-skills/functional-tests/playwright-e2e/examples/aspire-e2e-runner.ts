import { exec } from "child_process";
import { promisify } from "util";

const execAsync = promisify(exec);

/**
 * Runner/Agente E2E con Aspire
 *
 * RESPONSABILIDADES:
 * 1. Iniciar Aspire AppHost
 * 2. Esperar hasta que TODOS los servicios estén disponibles (usando herramientas MCP de Aspire)
 * 3. Ejecutar Playwright SOLO cuando todo está listo
 * 4. Cleanup: Detener Aspire al finalizar
 *
 * IMPORTANTE: Playwright NO debe tener lógica de espera de Aspire.
 * Este runner es quien garantiza que los servicios están listos antes de ejecutar tests.
 */
async function runE2ETests() {
  try {
    // Paso 1: Iniciar Aspire
    console.log("🚀 Starting Aspire AppHost...");
    const aspireProcess = exec("aspire run");

    // Paso 2: Esperar a que servicios estén listos
    console.log("⏳ Waiting for services to be ready...");
    await waitForServices({
      frontend: "http://localhost:4200",
      authApi: "https://localhost:5001/health",
      timeout: 120000,
    });

    // Paso 3: Ejecutar tests de Playwright
    console.log("🧪 Running Playwright E2E tests...");
    const { stdout, stderr } = await execAsync("npx playwright test");
    console.log(stdout);

    if (stderr) {
      console.error("⚠️ Test warnings:", stderr);
    }

    console.log("✅ E2E tests completed successfully!");
  } catch (error) {
    console.error("❌ E2E test execution failed:", error);
    process.exit(1);
  } finally {
    // Cleanup: Detener Aspire
    console.log("🛑 Stopping Aspire services...");
    await execAsync("pkill -f aspire");
  }
}

async function waitForServices(
  services: Record<string, string>,
  options = { timeout: 120000 }
) {
  const startTime = Date.now();

  for (const [name, url] of Object.entries(services)) {
    let ready = false;

    while (!ready) {
      // Verificar timeout global (para TODOS los servicios)
      if (Date.now() - startTime > options.timeout) {
        throw new Error(
          `Timeout waiting for services. Last checking: ${name} at ${url}. Total time: ${Math.round((Date.now() - startTime) / 1000)}s`
        );
      }

      try {
        const response = await fetch(url, { method: "HEAD" });
        if (response.ok) {
          console.log(`✓ ${name} is ready`);
          ready = true;
        } else {
          console.log(`⏳ ${name} returned status ${response.status}, waiting...`);
          await new Promise((resolve) => setTimeout(resolve, 2000));
        }
      } catch (error) {
        // Service not ready yet
        console.log(`⏳ ${name} not ready yet, retrying...`);
        await new Promise((resolve) => setTimeout(resolve, 2000));
      }
    }
  }

  console.log(`✅ All services ready in ${Math.round((Date.now() - startTime) / 1000)}s`);
}

// Ejecutar
runE2ETests();
