# Guía para Agentes: Ejecutar Tests E2E con Aspire

> Esta guía es para agentes de IA que coordinan la ejecución de tests E2E en proyectos con .NET
> Aspire

## 🎯 Tu Responsabilidad como Agente

**TÚ eres el coordinador**. Tu trabajo es:

1. ✅ Iniciar Aspire
2. ✅ Esperar hasta que TODOS los servicios estén listos
3. ✅ Ejecutar Playwright cuando todo esté disponible
4. ✅ Reportar resultados
5. ✅ Detener Aspire (cleanup)

**Playwright NO debe hacer nada de esto**. Solo ejecuta tests cuando se lo ordenas.

## 📋 Checklist de Ejecución

### Paso 1: Verificar Prerequisitos

```typescript
// Verificar que tienes acceso a herramientas MCP necesarias
const requiredTools = [
  "aspire_mcp_tools", // Para gestionar Aspire
  "playwright_mcp_tools", // Para ejecutar tests
  "angular_mcp_tools", // Para interactuar con frontend
];

// Verificar que playwright.config.aspire.ts está configurado
// (sin webServer, sin globalSetup de espera)
```

### Paso 2: Iniciar Aspire

```typescript
// Usando herramientas MCP de Aspire o exec
const aspireProcess = exec("aspire run");
console.log("🚀 Aspire AppHost iniciado");
```

### Paso 3: Esperar Servicios (TU RESPONSABILIDAD)

**Opción A: Usar herramientas MCP de Aspire (RECOMENDADO)**

```typescript
// Usar herramientas MCP de Aspire para verificar estado
await aspire.waitForServices({
  services: [
    { name: "frontend", type: "angular", port: 4200 },
    { name: "auth-api", type: "webapi", port: 5001 },
    { name: "database", type: "sqlserver", port: 1433 },
  ],
  timeout: 120000, // 2 minutos
});

console.log("✅ Todos los servicios verificados y listos");
```

**Opción B: Verificación manual (alternativa)**

```typescript
// Si no hay herramientas MCP, verificar manualmente
async function waitForServices() {
  const services = {
    frontend: "http://localhost:4200",
    authApi: "https://localhost:5001/health",
  };

  for (const [name, url] of Object.entries(services)) {
    let ready = false;
    const maxAttempts = 60; // 2 minutos
    let attempt = 0;

    while (!ready && attempt < maxAttempts) {
      try {
        const response = await fetch(url, { method: "HEAD" });
        if (response.ok) {
          console.log(`✓ ${name} ready`);
          ready = true;
        }
      } catch (error) {
        attempt++;
        console.log(`⏳ ${name} not ready (${attempt}/${maxAttempts})`);
        await new Promise((resolve) => setTimeout(resolve, 2000));
      }
    }

    if (!ready) {
      throw new Error(`Timeout: ${name} no disponible después de 2 minutos`);
    }
  }
}

await waitForServices();
```

### Paso 4: Ejecutar Playwright

```typescript
// SOLO cuando servicios están listos
console.log("🧪 Ejecutando tests E2E con Playwright...");

const { stdout, stderr } = await execAsync("npx playwright test");

console.log(stdout);

if (stderr) {
  console.error("⚠️ Warnings:", stderr);
}

console.log("✅ Tests completados");
```

### Paso 5: Cleanup (SIEMPRE)

```typescript
try {
  // ... pasos anteriores
} finally {
  // SIEMPRE detener Aspire, incluso si tests fallan
  console.log("🛑 Deteniendo Aspire...");
  await execAsync("pkill -f aspire");
  console.log("✅ Cleanup completado");
}
```

## ⚠️ Errores Comunes a Evitar

### ❌ ERROR 1: Ejecutar Playwright sin verificar servicios

```typescript
// ❌ MAL
exec("aspire run");
await execAsync("npx playwright test"); // ¡Servicios pueden no estar listos!
```

### ❌ ERROR 2: Delegar espera a Playwright

```typescript
// ❌ MAL - NO hagas esto
// playwright.config.ts
export default defineConfig({
  globalSetup: "./wait-for-aspire.ts", // ❌ Esta es TU responsabilidad
});
```

### ❌ ERROR 3: No hacer cleanup

```typescript
// ❌ MAL
async function runTests() {
  exec("aspire run");
  await waitForServices();
  await execAsync("npx playwright test");
  // ❌ Aspire sigue ejecutándose y consumiendo recursos
}
```

## ✅ Plantilla Completa Correcta

```typescript
async function executeE2ETests() {
  let aspireStarted = false;

  try {
    // 1. Iniciar Aspire
    console.log("🚀 Iniciando Aspire AppHost...");
    exec("aspire run");
    aspireStarted = true;

    // 2. Esperar servicios (TU RESPONSABILIDAD)
    console.log("⏳ Esperando a que servicios estén disponibles...");
    await waitForServices({
      frontend: "http://localhost:4200",
      authApi: "https://localhost:5001/health",
      timeout: 120000,
    });

    // 3. Verificación adicional de dashboard
    console.log("📊 Verificando Aspire Dashboard...");
    const dashboardResponse = await fetch("http://localhost:15888");
    if (!dashboardResponse.ok) {
      throw new Error("Aspire Dashboard no disponible");
    }

    // 4. Ejecutar Playwright (cuando todo está listo)
    console.log("🧪 Ejecutando tests E2E...");
    const result = await execAsync("npx playwright test");

    // 5. Procesar resultados
    console.log("📊 Resultados:");
    console.log(result.stdout);

    if (result.stderr) {
      console.warn("⚠️ Warnings:", result.stderr);
    }

    console.log("✅ Tests E2E completados exitosamente");
    return { success: true, output: result.stdout };
  } catch (error) {
    console.error("❌ Error ejecutando tests E2E:", error);
    return { success: false, error: error.message };
  } finally {
    // 6. Cleanup (SIEMPRE)
    if (aspireStarted) {
      console.log("🛑 Deteniendo Aspire AppHost...");
      try {
        await execAsync("pkill -f aspire");
        console.log("✅ Aspire detenido correctamente");
      } catch (cleanupError) {
        console.error("⚠️ Error deteniendo Aspire:", cleanupError);
      }
    }
  }
}
```

## 🔍 Verificación Pre-ejecución

Antes de ejecutar tests, verifica:

```typescript
async function preExecutionChecks() {
  // 1. Verificar que playwright.config.aspire.ts existe
  const configExists = await fileExists("playwright.config.aspire.ts");
  if (!configExists) {
    throw new Error("Configuración de Playwright para Aspire no encontrada");
  }

  // 2. Verificar que puertos están libres
  const ports = [4200, 5001, 15888]; // Frontend, API, Dashboard
  for (const port of ports) {
    const inUse = await isPortInUse(port);
    if (inUse) {
      console.warn(`⚠️ Puerto ${port} ya está en uso`);
    }
  }

  // 3. Verificar que herramientas MCP están disponibles
  // (implementación depende de tu framework)
}
```

## 📊 Reportar Resultados al Usuario

```typescript
// Ejemplo de reporte estructurado
function reportResults(result) {
  if (result.success) {
    return `
✅ **Tests E2E Completados Exitosamente**

- Total de tests ejecutados: ${parseTestCount(result.output)}
- Tests pasados: ${parsePassedTests(result.output)}
- Duración: ${parseDuration(result.output)}

Ver reporte completo en: test-results/index.html
    `;
  } else {
    return `
❌ **Tests E2E Fallaron**

Error: ${result.error}

Pasos para debug:
1. Verificar logs de Aspire Dashboard: http://localhost:15888
2. Comprobar que todos los servicios están en estado "Running"
3. Revisar logs de tests en: test-results/
    `;
  }
}
```

## 🎯 Resumen

**Como agente, SIEMPRE sigue este orden**:

1. Iniciar Aspire
2. Esperar servicios (usando MCP tools o verificación manual)
3. Verificar que TODO está listo
4. **Entonces y solo entonces**, ejecutar Playwright
5. Procesar resultados
6. **SIEMPRE** hacer cleanup

**Nunca**:

- ❌ Ejecutes Playwright antes de verificar servicios
- ❌ Delegues la espera de servicios a Playwright
- ❌ Olvides hacer cleanup de Aspire

## 📚 Referencias

- [ASPIRE-E2E-FLOW.md](ASPIRE-E2E-FLOW.md) - Flujo completo detallado
- [SKILL.md](../SKILL.md#e2e-testing-with-aspire) - Documentación completa
- [aspire-e2e-runner.ts](aspire-e2e-runner.ts) - Ejemplo de implementación
