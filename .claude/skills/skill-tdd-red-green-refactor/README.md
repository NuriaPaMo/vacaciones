# TDD Red-Green-Refactor Skill

Este skill proporciona una guía completa de la metodología Test-Driven Development (TDD) con el ciclo Red-Green-Refactor, aplicable tanto a backend como frontend.

## ¿Por qué este skill?

- **Disciplina de desarrollo**: TDD fuerza a pensar antes de codificar
- **Código testeable por diseño**: El diseño emerge de los tests
- **Refactoring seguro**: Los tests protegen contra regresiones
- **Documentación viva**: Los tests documentan el comportamiento esperado
- **Agnóstico de tecnología**: Se aplica a .NET, TypeScript, Python, etc.

## El Ciclo TDD

```text
RED 🔴 → Escribir test que falla
  ↓
GREEN 🟢 → Código mínimo para pasar
  ↓
REFACTOR 🔵 → Mejorar sin romper tests
  ↓
¿Feature completa? → NO: volver a RED
                   → SÍ: Done ✅
```

## Ejemplos de Uso

### Ejemplo 1: Backend - Entidad de Dominio

**Input al Copilot:**

```text
Usa TDD para implementar la entidad Account con validación de código
```

**Copilot cargará este skill y seguirá:**

**RED Phase:**

```csharp
[Fact]
public void Create_WithEmptyCode_ShouldFail()
{
    var result = Account.Create("", "Dev");
    result.IsFailure.Should().BeTrue();
}
```

**GREEN Phase:**

```csharp
public static Result<Account> Create(string code, string name)
{
    if (string.IsNullOrEmpty(code))
        return Result<Account>.Failure("Code required");
    return Result<Account>.Success(new Account(code, name));
}
```

**REFACTOR Phase:**

- Extraer validación a método
- Crear value object AccountCode
- Aplicar SOLID principles

### Ejemplo 2: Frontend - Store de Pinia

**Input al Copilot:**

```text
Implementa con TDD la acción addTimeEntry en el store
```

**Copilot seguirá el ciclo:**

**RED:**

```typescript
it('should add entry to store', () => {
  const store = useTimeEntryStore();
  store.addEntry({ hours: 2, account: 'DEV' });
  expect(store.entries).toHaveLength(1);
});
```

**GREEN:**

```typescript
actions: {
  addEntry(entry: TimeEntry) {
    this.entries.push(entry);
  }
}
```

**REFACTOR:**

- Validación extraída
- Normalización de datos
- Manejo de duplicados

### Ejemplo 3: Bug Fix con TDD

**Input al Copilot:**

```text
Hay un bug: las horas negativas se aceptan. Arréglalo con TDD
```

**Copilot seguirá:**

**RED:**

```typescript
it('should reject negative hours', () => {
  const result = validateHours(-2);
  expect(result.isValid).toBe(false);
  expect(result.error).toBe('Hours must be positive');
});
// Test FALLA ✅ - reproduce el bug
```

**GREEN:**

```typescript
function validateHours(hours: number) {
  if (hours <= 0) {
    return { isValid: false, error: 'Hours must be positive' };
  }
  return { isValid: true };
}
// Test PASA ✅ - bug arreglado
```

**REFACTOR:**

- Extraer constante MIN_HOURS = 0
- Mejorar mensaje de error
- Reutilizar en otros validadores

## Cuándo Usar TDD vs BDD

| Escenario          | Metodología | Herramienta                 |
| ------------------ | ----------- | --------------------------- |
| User story con ACs | BDD         | Gherkin/Reqnroll            |
| Entidad de dominio | TDD         | xUnit/Vitest                |
| Algoritmo complejo | TDD         | xUnit/Vitest                |
| Bug fix            | TDD         | xUnit/Vitest                |
| API endpoint       | BDD         | Gherkin + integration tests |
| Utilidades/helpers | TDD         | xUnit/Vitest                |

## Integración con Bolt Framework

### Con @Bolt Framework Testing

```text
@Bolt Framework Testing usa TDD para implementar AccountService
```

→ Generará tests RED → GREEN → REFACTOR automáticamente

### Con skill-backend-testing-dotnet

- TDD proporciona el **workflow**
- skill-backend-testing-dotnet proporciona las **herramientas** (xUnit, Moq, etc.)

### Con skill-playwright-e2e

TDD también aplica a E2E:

- RED: Escribir test E2E que falla
- GREEN: Implementar feature
- REFACTOR: Mejorar page objects

## Métricas de Éxito

### TDD Funciona Bien Cuando

- ✅ Ciclos cortos (< 30 minutos)
- ✅ Tests verdes la mayoría del tiempo
- ✅ Refactoring sin miedo
- ✅ Cobertura alta naturalmente
- ✅ Bugs detectados temprano

### Señales de Alerta

- ❌ Ciclos > 1 hora
- ❌ Tests rotos frecuentemente
- ❌ Miedo a refactorizar
- ❌ Huecos en cobertura
- ❌ Tests como carga

## Anti-Patrones a Evitar

### ❌ Tests Después de Implementar

```typescript
// INCORRECTO
function add(a, b) {
  return a + b;
} // Código primero

test('should add', () => {
  expect(add(2, 3)).toBe(5); // Test después
});
```

### ✅ Tests Antes de Implementar (TDD)

```typescript
// CORRECTO - RED
test('should add', () => {
  expect(add(2, 3)).toBe(5); // Test primero (falla)
});

// GREEN
function add(a, b) {
  return a + b;
} // Código después
```

### ❌ Saltarse la Fase RED

```typescript
// INCORRECTO: Test pasa inmediatamente
test('should return true', () => {
  expect(true).toBe(true); // ¿Para qué sirve?
});
```

### ❌ Testear Implementación

```typescript
// INCORRECTO: Test frágil
test('should call _internal', () => {
  const spy = jest.spyOn(obj, '_internal');
  obj.method();
  expect(spy).toHaveBeenCalled();
});

// CORRECTO: Test comportamiento
test('should return expected result', () => {
  const result = obj.method();
  expect(result).toBe(expected);
});
```

## Comandos Comunes

### Backend (.NET)

```bash
# RED: Ejecutar test específico
dotnet test --filter "Create_WithEmptyCode_ShouldFail"

# GREEN: Ejecutar todos
dotnet test

# REFACTOR: Con cobertura
dotnet test /p:CollectCoverage=true

# Watch mode (auto run)
dotnet watch test
```

### Frontend (TypeScript)

```bash
# RED: Test específico
npm test -- TimeEntryStore.test.ts

# GREEN: Todos los tests
npm test

# REFACTOR: Con cobertura
npm test -- --coverage

# Watch mode
npm test -- --watch
```

## Archivos Relacionados

### Skill Principal

- [SKILL.md](./SKILL.md) - Instrucciones detalladas del skill (versión concisa)

### Ejemplos Detallados

La carpeta `examples/` contiene ejemplos completos con código de contexto:

- [red-phase-examples.md](./examples/red-phase-examples.md) - Ejemplos de fase RED para .NET y TypeScript
- [green-phase-examples.md](./examples/green-phase-examples.md) - Ejemplos de fase GREEN con requisitos complejos
- [refactor-phase-examples.md](./examples/refactor-phase-examples.md) - Ejemplos before/after de refactoring
- [anti-patterns.md](./examples/anti-patterns.md) - Anti-patrones detallados y cómo evitarlos

### Otros Skills Bolt Framework

- [../skill-backend-testing-dotnet](../skill-backend-testing-dotnet/) - Herramientas para backend
- [../skill-gherkin-reqnroll](../skill-gherkin-reqnroll/) - Alternativa BDD approach
- [../skill-playwright-e2e](../skill-playwright-e2e/) - Testing E2E frontend

### Agentes Bolt Framework

- [../../agents/bolt-testing.agent.md](../../agents/bolt-testing.agent.md) - Agente Testing

## Referencias

- [Test Driven Development: By Example - Kent Beck](https://www.amazon.com/Test-Driven-Development-Kent-Beck/dp/0321146530)
- [The Cycles of TDD - Uncle Bob](https://blog.cleancoder.com/uncle-bob/2014/12/17/TheCyclesOfTDD.html)
- [.NET Testing Best Practices](https://docs.microsoft.com/en-us/dotnet/core/testing/unit-testing-best-practices)
