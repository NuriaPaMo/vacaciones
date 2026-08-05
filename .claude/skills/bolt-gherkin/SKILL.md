---
name: bolt-gherkin
description: "Generate BDD scenarios in Gherkin syntax for Reqnroll (.NET) or Playwright (frontend) from user stories and acceptance criteria, marking `@smoke` per Bolt smoke-classification rules. Generates compilable Reqnroll step definition stubs. Runs in parallel with bolt-plan. Produces `specs/[feature]/tests/*.feature` files. Triggers: 'generate Gherkin', 'BDD scenarios', 'Reqnroll', 'feature file', 'Given When Then', '/bolt-gherkin'."
---

# Bolt Gherkin — Methodology

Translate user stories and acceptance criteria into executable BDD scenarios
using Gherkin syntax. Generate compilable step definition stubs for Reqnroll.

**Bolt Framework Stage**: PLAN (paralelo con bolt-plan)
**Trigger**: Se invoca simultáneamente con bolt-plan tras completar bolt-feature.
**Input**: `specs/[XXX]/requirements/requirements.md`
**Output**: `specs/[XXX]/tests/*.feature` + stubs ejecutables (Reqnroll / Playwright)
**Consumidor downstream**: bolt-tasks (reconciliación plan ↔ gherkin)
**Responsible Agent**: BDD Author

## Scenario detection (MANDATORY)

Antes de generar `.feature` files, leer `.boltf/memory/constitution.digest.md` y/o
`specs/[XXX]/requirements/requirements.md` para determinar el escenario activo:

- `backend-only` → cargar `gherkin-reqnroll`; output bajo
  `tests/<Module>.ReqnrollTests/Features/` + generar stubs de step definitions.
- `frontend-only` → cargar `playwright-e2e`; output `.feature` bajo
  `specs/[XXX]/tests/<feature>.feature` (documentación BDD) **+ stub
  ejecutable** bajo `src/frontend/e2e/tests/<feature>/<component>.spec.ts`.
- `backend+frontend` / `fullstack` → ambas skills; un `.feature` Reqnroll por
  API + un spec Playwright por flujo UI.
- `infra-only` → **NO generar Gherkin**. Ver sección "Escenario infra-only".

Declarar el escenario detectado al inicio del comentario del `.feature` file.

## Escenario infra-only

NO generar Gherkin. Infra se valida con:

- `az deployment group what-if` (pre-deploy)
- Policy-as-code (Azure Policy / OPA)
- Integration tests post-provisioning

Si se necesitan tests de infra, delegar a `bolt-testing`.

Documentar en output: "Escenario infra-only: Gherkin omitido. Validación
delegada a bolt-testing + IaC what-if."

## Output location

- **Documentación BDD** (`.feature`): `specs/[XXX-feature-name]/tests/[feature].feature`
- **Step definitions Reqnroll** (`.cs`): `tests/[Module].ReqnrollTests/StepDefinitions/[Feature]Steps.cs`
- **Tests ejecutables Playwright** (`.spec.ts`): `src/frontend/e2e/tests/<feature>/<component>.spec.ts`

> ⚠️ **Distinción crítica**: los `.feature` en `specs/` son documentación;
> los `.spec.ts` en `src/frontend/e2e/tests/` son los tests ejecutables que
> los quality gates comprueban. Ambos deben existir para bolts frontend.

## Process

1. Read `requirements.md` user stories and acceptance criteria.
2. For each User Story, create a `Feature:` block with scenarios per AC.
3. Apply granularity rules (ver sección "Granularidad").
4. Use Given/When/Then steps, reusing existing step definitions from
   `tests/[Module].ReqnrollTests/Features/` when possible.
5. Apply `@smoke` tag using the matrix from `bolt-smoke-testing`.
6. Group scenarios under `Rule:` blocks when business rules cluster them.
7. **[backend/fullstack]** Generar stubs de step definitions (ver sección).
8. **[frontend/fullstack]** Para cada flujo UI cubierto, generar el stub
   `.spec.ts` en `src/frontend/e2e/tests/<feature>/<component>.spec.ts`.

## Granularidad: Scenario vs Scenario Outline

Regla explícita para decidir cuándo usar cada forma:

- Si **≥3 ACs del mismo US** varían solo en datos de entrada/salida →
  **Scenario Outline** con Examples table.
- Si los ACs tienen **flujos distintos** (diferentes pasos Given/When/Then) →
  **Scenarios individuales**.
- **Máximo 8 scenarios por .feature file**. Si se excede → split por
  `Rule:` sub-feature o crear un segundo `.feature` file.

Ejemplos de cuándo usar cada uno:

```gherkin
# Scenario Outline — mismos pasos, datos distintos
Scenario Outline: Validar campo <field> rechaza valor inválido
  Given un formulario de registro
  When introduzco "<value>" en el campo "<field>"
  Then veo el error "<error>"
  Examples:
    | field | value | error |
    | email | noarroba | Email inválido |
    | phone | abc | Teléfono inválido |
    | age | -1 | Edad debe ser positiva |

# Scenarios individuales — flujos distintos
Scenario: Login exitoso con credenciales válidas
  Given un usuario registrado
  When introduzco email y password correctos
  Then accedo al dashboard

Scenario: Login bloqueado tras 3 intentos fallidos
  Given un usuario con 2 intentos fallidos
  When introduzco password incorrecto
  Then la cuenta se bloquea y veo mensaje de contacto con soporte
```

## Step definition stubs (backend / Reqnroll)

**Para escenario `backend-only` o `fullstack`:**

Para cada `.feature` generado:

1. Crear `tests/[Module].ReqnrollTests/StepDefinitions/[Feature]Steps.cs`
2. Generar clase con:
   - Un método por step (Given/When/Then)
   - Atributo `[Given("...")]`, `[When("...")]`, `[Then("...")]` con el
     texto exacto del step
   - Body: `throw new NotImplementedException("// TODO: implement");`
   - Using statements correctos (`Reqnroll`, `FluentAssertions`)
3. El stub **DEBE compilar** con `dotnet build`.
4. El stub **DEBE fallar** al ejecutar `dotnet test` (NotImplementedException).

Esto garantiza que:

- bolt-implement tiene un punto de partida ejecutable
- Los quality gates nunca son silenciosos
- El binding pattern está pre-establecido (naming, namespace, structure)

### Ejemplo de stub generado

```csharp
using Reqnroll;
using FluentAssertions;

namespace Module.ReqnrollTests.StepDefinitions;

[Binding]
public class LoginFeatureSteps
{
    [Given(@"un usuario registrado con email ""(.*)""")]
    public void GivenUnUsuarioRegistradoConEmail(string email)
    {
        throw new NotImplementedException("// TODO: implement");
    }

    [When(@"introduzco credenciales válidas")]
    public void WhenIntroduzcoCredencialesValidas()
    {
        throw new NotImplementedException("// TODO: implement");
    }

    [Then(@"recibo un token JWT válido")]
    public void ThenReciboUnTokenJwtValido()
    {
        throw new NotImplementedException("// TODO: implement");
    }
}
```

## Playwright stubs (frontend / fullstack)

Para cada flujo UI cubierto, generar stub en
`src/frontend/e2e/tests/<feature>/<component>.spec.ts`:

- Importar `{ test }` de `@playwright/test`.
- Declarar cada escenario `@smoke` del `.feature` como un `test()` con
  `test.fail()` y un comentario `// TODO: implement — AC-XXX`.
- Esto garantiza que `npx playwright test --grep @smoke` devuelve
  ≥1 test y el gate **nunca es silencioso**.

## Style

```gherkin
@feature-name
Feature: [Feature name]
  As a [role]
  I want [capability]
  So that [benefit]

  Background:
    Given [common precondition]

  @smoke
  Scenario: [AC-001.1 happy path]
    Given [context]
    When [action]
    Then [outcome]

  Scenario Outline: [parametric]
    Given [context with <param>]
    When [action]
    Then [outcome]
    Examples:
      | param | outcome |
```

## Stack-specific tooling

- **.NET / Reqnroll**: `gherkin-reqnroll` skill for syntax, hooks, and step
  definitions. Output goes under `tests/<Module>.ReqnrollTests/Features/`.
- **Frontend / Playwright**: `playwright-e2e` for tags and BDD-style tests.

## Smoke classification

Every P1 user story must have at least one `@smoke` scenario.
Aim for 20-50 % `@smoke` per US.

## Quality gates

- Each AC maps to at least one Gherkin scenario.
- Smoke tags applied per `bolt-smoke-testing` matrix.
- Scenarios compile / parse without errors.
- Reused step definitions where possible (no duplicate steps).
- **[backend/fullstack]** Step definition stubs compile with `dotnet build`.
- **[frontend/fullstack]** Playwright stubs exist and are discoverable by
  `npx playwright test --list`.

## Related agents (next steps)

- → `bolt-tasks`: reconciles gherkin output with plan for full coverage.
- → `bolt-implement`: implement code to make scenarios pass (fills stubs).
- → `bolt-analyze`: verify AC ↔ Gherkin alignment.
- → `bolt-testing`: additional test generation beyond BDD.

## References

- `.github/prompts/bolt-gherkin.prompt.md`
