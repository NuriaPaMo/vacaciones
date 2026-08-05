---
name: integration-e2e-testing
description:
  Comprehensive integration and E2E testing with Playwright, Aspire, Testcontainers and Respawn for .NET. Use when
  writing integration tests, E2E tests, database tests, or any test requiring real infrastructure.
---

# Integration & E2E Testing

## 🚨 CRITICAL RULES

- **NEVER use SQLite** for integration tests — SQL Server only.
- **NEVER reset database at END of test** — always reset at **START**.
- **NEVER create a new container per test** — use the shared infrastructure.

---

## Infrastructure Overview

The project has a multi-layer testing infrastructure already in place:

| Layer              | Infrastructure                                          | Source (tests/Tests.Common)          | Example                                                        |
| ------------------ | ------------------------------------------------------- | ------------------------------------ | -------------------------------------------------------------- |
| Integration tests  | `DatabaseFixture<TContext>` + `GlobalTestContainers`    | `Infrastructure/DatabaseFixture.cs`  | [examples/DatabaseFixture.cs](./examples/DatabaseFixture.cs)  |
| Shared container   | `GlobalTestContainers`                                  | `Infrastructure/GlobalTestContainers.cs` | [examples/GlobalTestContainers.cs](./examples/GlobalTestContainers.cs) |
| E2E (Playwright)   | `E2E.Testing.Api` + `DatabaseHelper` (path-based)      | `src/frontend/e2e/helpers/`          | [examples/database-helper.ts](./examples/database-helper.ts)  |
| E2E (Aspire full)  | `E2ETestBase` with `Aspire.Hosting.Testing`             | `Infrastructure/E2ETestBase.cs`      | [examples/E2ETestBase.cs](./examples/E2ETestBase.cs)          |

**Database strategy**:

- **Local dev**: LocalDB (no Docker needed)
- **CI**: `GlobalTestContainers` — ONE shared SQL Server container, `USE_TESTCONTAINERS=true`
- **Respawn**: ~200-300ms state reset between tests

---

## Integration Tests

### Pattern: DatabaseFixture + GlobalTestContainers

Each test project defines its own `DatabaseCollection` — see
[examples/database-collection.cs](./examples/database-collection.cs).

Full integration test with fixture lifecycle and test traits — see
[examples/integration-test.cs](./examples/integration-test.cs).

Infrastructure classes (self-contained copies):

- [examples/GlobalTestContainers.cs](./examples/GlobalTestContainers.cs) — shared SQL Server container
- [examples/DatabaseFixture.cs](./examples/DatabaseFixture.cs) — per-suite fixture with migrations + Respawn

Key rules:

- Set `ContextFactory` **before** calling `EnsureMigrationsAsync()` if your DbContext needs extra dependencies.
- `MultipleActiveResultSets=true` is required by Respawn — handled automatically by `DatabaseFixture`.
- Do **not** hardcode connection strings; rely on `_fixture.ConnectionString`.

### Required Trait Taxonomy (C#)

Every integration test class **must** include the mandatory traits and **should** include the
optional ones where applicable:

| Trait        | Required | Values                                                        |
| ------------ | -------- | ------------------------------------------------------------- |
| `Category`   | ✅        | `Unit` \| `Integration` \| `E2E` \| `Architecture`           |
| `Speed`      | ✅        | `Fast` (< 100ms) \| `Medium` (< 5s) \| `Slow` (> 5s)        |
| `Feature`    | ✅        | Bounded context name: `Auth`, `Clientes`, `Usuarios`, …      |
| `Layer`      | ✅        | `Domain` \| `Application` \| `Infrastructure`                |
| `Database`   | ⚠        | `Required` — include whenever the test needs a real DB       |
| `Type`       | ⚠        | `HealthCheck` \| `Migration` \| `EventHandler` \| `BackgroundJob` \| `Structural` \| `Observability` |
| `UserStory`  | ⚠        | `US-XXX-NNN` — link to the acceptance criterion under test   |

Run specific subsets:

```bash
dotnet test --filter "Category=Integration&Feature=Clientes"
dotnet test --filter "Category=Integration&Database=Required"
dotnet test --filter "UserStory=US-CLI-001"
```

---

## E2E Tests (Playwright)

Playwright workers interact with the backend via the **E2E Testing API** (`tests/E2E.Testing.Api`)
using path-based routing. Each Playwright worker maps to isolated databases:

```text
Worker 0 → AuthDb_Worker0, UsuariosDb_Worker0  (port 5002)
Worker 1 → AuthDb_Worker1, UsuariosDb_Worker1  (port 5002, path /api/testing/1/...)
```

Full annotated example — see [examples/e2e-playwright.spec.ts](./examples/e2e-playwright.spec.ts).

`DatabaseHelper` self-contained copy — see [examples/database-helper.ts](./examples/database-helper.ts).

### Tag Taxonomy (Playwright)

Include tags in the file-level JSDoc **and** in the `{ tag }` option of `test()` / `test.describe()`.
Tags are cumulative — a smoke test is also a regression test.

| Tag            | Purpose                                                                 | Run in CI? |
| -------------- | ----------------------------------------------------------------------- | ---------- |
| `@smoke`       | Critical happy-path; must pass before any deployment                    | pre-deploy |
| `@regression`  | Full suite; run on every PR / merge to `main`                           | always     |
| `@integration` | Requires real backend + database (most E2E tests)                       | always     |
| `@manual`      | Never runs automatically; execute with `--grep @manual`                 | ❌          |
| `@<feature>`   | Bounded context: `@clientes`, `@usuarios`, `@auth`, `@encargos`, …     | filtered   |
| `@<action>`    | Specific scenario: `@create`, `@edit`, `@search`, `@delete`, `@login`  | filtered   |

**Classification rules**:

- Login / health / navigation → `@smoke @regression`
- CRUD happy paths → `@smoke @regression @integration`
- Edge/validation/error scenarios → `@regression @integration`
- Debug helpers or WIP → `@manual`

Running subsets:

```bash
npx playwright test --grep @smoke            # pre-deploy check
npx playwright test --grep @regression       # full PR suite
npx playwright test --grep "@clientes"       # single feature
npx playwright test --grep-invert @manual    # exclude manual (default in CI)
```

### Database Reset in Playwright Tests

Use the existing `DatabaseHelper` in `src/frontend/e2e/helpers/database-helper.ts`:

```typescript
const db = new DatabaseHelper(request); // auto-detects TEST_PARALLEL_INDEX
await db.resetAndSeed();               // → POST /api/testing/{workerIndex}/reset-and-seed-all
```

### Worker Configuration (playwright.config.ts)

- Dev: 2 workers | CI: 4 workers | Debug: 1 worker (`DEBUG_MODE=true`)
- `TEST_PARALLEL_INDEX` is the stable worker identifier (not `TEST_WORKER_INDEX`)

---

## E2E Tests (Aspire Full Stack)

For C#-based E2E tests that require the entire Aspire AppHost — see
[examples/e2e-aspire.cs](./examples/e2e-aspire.cs).

`E2ETestBase` self-contained copy — see [examples/E2ETestBase.cs](./examples/E2ETestBase.cs).

`E2ETestBase` starts the full Aspire AppHost (SQL Server → Migrators → APIs) and waits for health
checks before tests run. Use `[Trait("Category", "E2E")]` and `[Trait("Speed", "Slow")]`.

---

## Adding a New Service to the E2E Infrastructure

When a new bounded context requires E2E database isolation:

1. Register a `TestDatabaseManager` for the new service in `tests/E2E.Testing.Api/Program.cs`
2. Add migration + Respawn reset in `TestingController.GetOrCreateWorkersManagersAsync`
3. Add the connection string to `appsettings.E2E.json` with `MultipleActiveResultSets=true`

---

## DO / DON'T

| ✅ DO                                                                   | ❌ DON'T                                                                    |
| ----------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| Use `DatabaseFixture<TContext>` for integration tests                   | Use SQLite or in-memory databases                                           |
| Call `ResetDatabaseAsync()` at the **START** of each test              | Reset database at end of test                                               |
| Call `EnsureMigrationsAsync()` after setting `ContextFactory`          | Create new containers per test                                              |
| Use `[Collection("Database")]` + `GlobalTestContainers` in CI          | Skip `MultipleActiveResultSets=true` in connection strings                  |
| Use `DatabaseHelper` from `e2e/helpers/` for Playwright DB reset       | Use `TEST_WORKER_INDEX` to identify workers (use `TEST_PARALLEL_INDEX`)     |
| Use `E2ETestBase` for full Aspire stack E2E tests                      | Share `DbContext` instances between tests                                   |
| Tag all C# tests with `Category`, `Speed`, `Feature`, `Layer` traits   | Omit `[Trait("Database", "Required")]` on tests that use a real DB         |
| Tag Playwright tests with `@smoke` and/or `@regression` + `@<feature>` | Use `@manual` for tests intended to run in CI                               |
| Classify happy-path flows as `@smoke @regression`                      | Mix `@smoke` and `@manual` on the same test                                 |

---

## Related Skills

| Skill                    | Scope                                                                 |
| ------------------------ | --------------------------------------------------------------------- |
| `backend-testing-dotnet` | Unit tests, architecture tests (`MicroserviceConfig`), coverage       |
| `playwright-e2e`         | Playwright POM, locators, assertions, visual regression, accessibility |

---

**Coverage Targets**: Infrastructure layer ≥ 80% | Repository layer ≥ 90%
