# Playwright E2E - Ejemplos

Esta carpeta contiene ejemplos prácticos de implementación de tests E2E con Playwright.

## Archivos de Ejemplo

### 📘 Documentación

- **[AGENT-GUIDE.md](AGENT-GUIDE.md)** - 🤖 **Guía completa para agentes de IA** que ejecutan tests
  E2E con Aspire (LEER SI ERES UN AGENTE)
- **[ASPIRE-E2E-FLOW.md](ASPIRE-E2E-FLOW.md)** - 🎯 **Guía rápida del flujo completo** E2E con
  Aspire (referencia rápida)

### Configuración

- **[playwright.config.ts](playwright.config.ts)** - Configuración completa de Playwright con
  múltiples navegadores, reportes y servidor web automático
- **[playwright.config.aspire.ts](playwright.config.aspire.ts)** - Configuración específica para
  trabajar con .NET Aspire (sin webServer, con global setup)

### TypeScript Examples

- **[LoginPage.ts](LoginPage.ts)** - Implementación del patrón Page Object Model para la página de
  login
- **[login.spec.ts](login.spec.ts)** - Suite de tests de autenticación con casos positivos y
  negativos
- **[api-mocking.spec.ts](api-mocking.spec.ts)** - Ejemplo de mocking de APIs para simular errores
- **[test-users.ts](test-users.ts)** - Fixtures personalizadas para usuarios autenticados
- **[visual-regression.spec.ts](visual-regression.spec.ts)** - Testing de regresión visual con
  screenshots
- **[accessibility.spec.ts](accessibility.spec.ts)** - Testing de accesibilidad con Axe Core

### Aspire Integration

- **[aspire-e2e-runner.ts](aspire-e2e-runner.ts)** - **Runner/agente principal** que coordina TODO:
  inicia Aspire, espera servicios, ejecuta Playwright
- **[aspire-global-setup.ts](aspire-global-setup.ts)** - Global setup OPCIONAL y simplificado (solo
  sanity check, el runner ya verificó servicios)
- **[aspire-mcp-verify-services.ts](aspire-mcp-verify-services.ts)** - Pseudocódigo para verificar
  servicios usando herramientas MCP de Aspire (usado por el runner)
- **[playwright.config.aspire.ts](playwright.config.aspire.ts)** - Configuración de Playwright para
  Aspire (SIN webServer, SIN lógica de espera)

### .NET Examples

- **[LoginTests.cs](LoginTests.cs)** - Tests de login usando Playwright para .NET con NUnit

### CI/CD

- **[e2e-tests.yml](e2e-tests.yml)** - GitHub Actions workflow para ejecución de tests E2E

## Uso

Todos estos ejemplos están referenciados desde el [SKILL.md](../SKILL.md) principal. Puedes copiar y
adaptar estos archivos a tus necesidades específicas.

## Estructura Recomendada

Cuando implementes estos ejemplos en tu proyecto, considera la siguiente estructura:

```text
tests/e2e/
├── playwright.config.ts          ← Copiar de aquí
├── tests/
│   ├── authentication/
│   │   └── login.spec.ts          ← Copiar de aquí
│   ├── time-tracking/
│   │   └── create-entry.spec.ts   ← Basado en api-mocking.spec.ts
│   ├── visual/
│   │   └── dashboard.spec.ts      ← Copiar de visual-regression.spec.ts
│   └── accessibility/
│       └── login.spec.ts          ← Copiar de accessibility.spec.ts
├── fixtures/
│   └── test-users.ts              ← Copiar de aquí
└── utils/
    └── page-objects/
        └── LoginPage.ts           ← Copiar de aquí
```

## Modificaciones Necesarias

Antes de usar estos ejemplos, ajusta:

1. **URLs**: Cambia `http://localhost:5173` por tu URL
2. **Selectores**: Adapta los selectores CSS/ARIA a tu aplicación
3. **Credenciales**: Usa credenciales de prueba de tu entorno
4. **Rutas de API**: Modifica las rutas de API según tu backend

## Ejecutar Tests con Aspire

Si tu proyecto usa .NET Aspire para orquestar servicios:

### Opción 1: Usar el Runner (Recomendado)

```bash
# El runner gestiona TODO: inicia Aspire, espera servicios, ejecuta Playwright
ts-node aspire-e2e-runner.ts
```

**IMPORTANTE**: El runner es responsable de:

- ✅ Iniciar Aspire con `aspire run`
- ✅ Esperar hasta que TODOS los servicios estén listos (usando herramientas MCP de Aspire)
- ✅ Ejecutar Playwright solo cuando todo está disponible
- ✅ Detener Aspire al finalizar (cleanup)

### Opción 2: Manualmente (Solo para desarrollo)

```bash
# Paso 1: Iniciar Aspire
aspire run

# Paso 2: Verificar Dashboard de Aspire (http://localhost:15888)
# Asegúrate de que TODOS los servicios están "Running" y "Healthy"

# Paso 3: SOLO cuando todo está listo, ejecutar Playwright
npx playwright test
```

**NOTA**: En este modo manual, TÚ eres responsable de verificar que Aspire está listo antes de
ejecutar Playwright.

### Configuración de Playwright

Usa la configuración específica de Aspire que NO tiene webServer ni lógica de espera:

```bash
cp playwright.config.aspire.ts ../../playwright.config.ts
```

Ver la sección "E2E Testing with Aspire" en [SKILL.md](../SKILL.md) para más detalles.
