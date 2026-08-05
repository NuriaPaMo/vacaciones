# Flujo E2E con Aspire - Guía Rápida

## 🎯 Arquitectura

```text
┌─────────────────────────────────────────────────────────────┐
│                    AGENTE/RUNNER                            │
│  (aspire-e2e-runner.ts)                                     │
│                                                             │
│  1. Inicia Aspire                                          │
│  2. Espera servicios (con MCP tools de Aspire)            │
│  3. Ejecuta Playwright cuando todo está listo             │
│  4. Hace cleanup                                           │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ├──► Aspire AppHost
                  │      └─► Frontend (Angular)
                  │      └─► Backend APIs
                  │      └─► Database
                  │
                  └──► Playwright Tests
                         (NO espera servicios,
                          solo ejecuta tests)
```

## ⚖️ Responsabilidades

### El AGENTE/RUNNER debe

- ✅ Iniciar Aspire: `aspire run`
- ✅ Usar herramientas MCP de Aspire para verificar servicios
- ✅ Esperar hasta que TODOS los servicios estén listos
- ✅ Ejecutar Playwright solo cuando servicios están disponibles
- ✅ Detener Aspire al finalizar (cleanup)

### Playwright NO debe

- ❌ Tener lógica de espera de Aspire
- ❌ Iniciar o detener servicios
- ❌ Verificar si Aspire está listo
- ❌ Configurar webServer (Aspire ya lo hace)

## 📋 Flujo Paso a Paso

### 1. El Runner Inicia Aspire

```typescript
const aspireProcess = exec("aspire run");
console.log("🚀 Aspire iniciado");
```

### 2. El Runner Espera Servicios

```typescript
// Usando herramientas MCP de Aspire
await aspire.waitForServices({
  services: [
    { name: "frontend", type: "angular", port: 4200 },
    { name: "auth-api", type: "webapi", port: 5001 },
    { name: "database", type: "sqlserver", port: 1433 },
  ],
  timeout: 120000,
});

// O verificación manual con fetch
await waitForServices({
  frontend: "http://localhost:4200",
  authApi: "https://localhost:5001/health",
});

console.log("✅ Todos los servicios listos");
```

### 3. El Runner Ejecuta Playwright

```typescript
// SOLO cuando servicios están listos
const { stdout, stderr } = await execAsync("npx playwright test");
console.log("🧪 Tests ejecutados");
```

### 4. El Runner Hace Cleanup

```typescript
try {
  // ... pasos anteriores
} finally {
  await execAsync("pkill -f aspire");
  console.log("🛑 Aspire detenido");
}
```

## 🔧 Archivos Clave

### aspire-e2e-runner.ts

**Propósito**: Runner principal que coordina TODO  
**Responsabilidad**: Iniciar Aspire, esperar servicios, ejecutar Playwright, cleanup

### playwright.config.aspire.ts

**Propósito**: Configuración de Playwright para Aspire  
**Características**:

- ❌ SIN webServer (Aspire lo gestiona)
- ❌ SIN globalSetup de espera (el runner ya verificó)
- ✅ Timeouts largos (15s actions, 30s navigation)
- ✅ baseURL configurable

### aspire-global-setup.ts

**Propósito**: OPCIONAL - Solo logging/sanity check  
**NO debe**: Esperar servicios (eso es responsabilidad del runner)

## ❌ Errores Comunes

### Error 1: Playwright espera servicios

```typescript
// ❌ MAL
// playwright.config.ts
export default defineConfig({
  globalSetup: "./wait-for-aspire.ts", // ❌ NO
});
```

### Error 2: Ejecutar sin verificar

```typescript
// ❌ MAL
exec("aspire run");
await execAsync("npx playwright test"); // ❌ Servicios pueden no estar listos
```

### Error 3: Sin cleanup

```typescript
// ❌ MAL
async function run() {
  exec("aspire run");
  await runTests();
  // ❌ Aspire sigue corriendo
}
```

## ✅ Flujo Correcto Completo

```typescript
async function runE2ETests() {
  try {
    // 1. Iniciar Aspire
    console.log("🚀 Starting Aspire...");
    exec("aspire run");

    // 2. Esperar servicios (RESPONSABILIDAD DEL RUNNER)
    console.log("⏳ Waiting for services...");
    await waitForServices({
      frontend: "http://localhost:4200",
      authApi: "https://localhost:5001/health",
    });

    // 3. Ejecutar Playwright (cuando todo está listo)
    console.log("🧪 Running tests...");
    const result = await execAsync("npx playwright test");
    console.log(result.stdout);

    console.log("✅ Success!");
  } catch (error) {
    console.error("❌ Failed:", error);
    process.exit(1);
  } finally {
    // 4. Cleanup (SIEMPRE)
    console.log("🛑 Stopping Aspire...");
    await execAsync("pkill -f aspire");
  }
}
```

## 🔍 Verificación Visual

Antes de ejecutar Playwright, verifica en Aspire Dashboard (<http://localhost:15888>):

- ✅ Todos los servicios en estado "Running"
- ✅ Todos los health checks en verde
- ✅ Frontend accesible en el navegador
- ✅ APIs respondiendo en sus endpoints

## 📚 Referencias

- [SKILL.md completo](../SKILL.md#e2e-testing-with-aspire)
- [aspire-e2e-runner.ts](aspire-e2e-runner.ts)
- [playwright.config.aspire.ts](playwright.config.aspire.ts)
