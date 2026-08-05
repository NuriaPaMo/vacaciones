/**
 * T000 - E2E Test: <Feature name> — <brief description>
 *
 * Based on the real patterns from:
 *   src/frontend/e2e/tests/users/create-user.spec.ts
 *   src/frontend/e2e/tests/users/search-users.spec.ts
 *
 * Tag taxonomy (include ALL that apply in the JSDoc @tag AND in { tag } options):
 *
 *   @smoke       → critical happy-path; MUST pass before any deployment
 *   @regression  → full suite; run on every PR / merge to main
 *   @integration → requires real backend + database (most E2E tests)
 *   @manual      → NEVER runs in CI; execute with: npx playwright test --grep @manual
 *   @<feature>   → bounded context: @clientes @usuarios @auth @encargos
 *   @<action>    → scenario type:  @create @edit @search @delete @login
 *
 * Classification rules:
 *   Login / health / navigation          → @smoke @regression
 *   CRUD happy paths                     → @smoke @regression @integration
 *   Edge / validation / error scenarios  → @regression @integration
 *   Debug helpers or WIP                 → @manual
 */

import { expect, test } from "../../fixtures/auth.fixture";
import { DatabaseHelper } from "../../helpers/database-helper";

/**
 * @tag @smoke @regression @integration @clientes @create
 */
test.describe("T000 - Create client", () => {
  /**
   * Reset and re-seed ALL databases for this worker before each test.
   *
   * DatabaseHelper auto-detects TEST_PARALLEL_INDEX to route calls to the
   * correct isolated databases:
   *   Worker 0 → ClientesDb_Worker0, AuthDb_Worker0  (all via port 5002)
   *   Worker 1 → ClientesDb_Worker1, AuthDb_Worker1
   *
   * Always call resetAndSeed() at the START of each test, never at the end.
   */
  test.beforeEach(async ({ request }) => {
    const db = new DatabaseHelper(request);
    await db.resetAndSeed(); // → POST /api/testing/{workerIndex}/reset-and-seed-all
  });

  // ── Happy-path (smoke + regression) ──────────────────────────────────────────

  test(
    "should create a new client successfully",
    { tag: ["@smoke", "@regression", "@integration"] },
    async ({ page }) => {
      // ARRANGE
      await page.goto("/clientes/crear");

      // ACT
      await page.getByLabel("Nombre").fill("Acme Corp");
      await page.getByLabel("NIF").fill("B12345678");
      await page.getByRole("button", { name: "Guardar" }).click();

      // ASSERT
      // Successful creation redirects to the detail page URL
      await expect(page).toHaveURL(/\/clientes\/[a-f0-9-]+$/, { timeout: 10_000 });
      await expect(page.getByText("Cliente creado correctamente")).toBeVisible();
    }
  );

  // ── Edge / validation (regression only) ──────────────────────────────────────

  test(
    "should show validation error for duplicate NIF",
    { tag: ["@regression", "@integration"] },
    async ({ page }) => {
      await page.goto("/clientes/crear");
      await page.getByLabel("NIF").fill("EXISTING-NIF");
      await page.getByRole("button", { name: "Guardar" }).click();

      await expect(page.getByText("El NIF ya está registrado")).toBeVisible();
    }
  );

  // ── Manual / debug (never in CI) ──────────────────────────────────────────────

  test.skip("debug: inspect network traffic during creation", { tag: "@manual" }, async ({ page }) => {
    const requests: string[] = [];
    page.on("request", (req) => requests.push(`${req.method()} ${req.url()}`));

    await page.goto("/clientes/crear");
    // … manual investigation steps …
    console.log(requests);
  });
});

// ─── Running subsets via CLI ───────────────────────────────────────────────────
//
//   Smoke only (fast pre-deploy check):
//     npx playwright test --grep @smoke
//
//   Full regression suite:
//     npx playwright test --grep @regression
//
//   Single feature:
//     npx playwright test --grep "@clientes"
//
//   Exclude manual tests (already excluded in CI by default):
//     npx playwright test --grep-invert @manual
//
//   Debug with single worker:
//     DEBUG_MODE=true npx playwright test
