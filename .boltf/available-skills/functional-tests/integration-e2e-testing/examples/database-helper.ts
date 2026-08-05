// Source: src/frontend/e2e/helpers/database-helper.ts
// Copied here so the skill examples are self-contained.
// DO NOT edit this copy — edit the source file instead.

import { APIRequestContext } from "@playwright/test";

/**
 * Helper for managing test databases from Playwright E2E tests.
 *
 * Architecture — Path-Based Routing (single process, port 5002):
 *
 *   Testing API listens on port 5002.
 *   Each Playwright worker uses a path prefix to target its own isolated databases:
 *     Worker 0 → /api/testing/0/…  → AuthDb_Worker0,   UsuariosDb_Worker0
 *     Worker 1 → /api/testing/1/…  → AuthDb_Worker1,   UsuariosDb_Worker1
 *     Worker 2 → /api/testing/2/…  → AuthDb_Worker2,   UsuariosDb_Worker2
 *
 *   Worker identification:
 *     Use TEST_PARALLEL_INDEX (stable, bounded 0..workers-1).
 *     Do NOT use TEST_WORKER_INDEX (can increment on worker restarts).
 *
 * Typical usage in a test spec:
 *
 *   test.beforeEach(async ({ request }) => {
 *     const db = new DatabaseHelper(request);
 *     await db.resetAndSeed();
 *   });
 */
export class DatabaseHelper {
  private readonly testingApiUrl: string;
  private readonly request: APIRequestContext;
  private readonly workerIndex: number;

  constructor(request: APIRequestContext, testingApiUrl?: string, workerIndex?: number | null) {
    this.request = request;
    this.workerIndex = workerIndex ?? this.detectWorkerIndex() ?? 0;
    // Always port 5002 — path-based routing handles worker isolation.
    this.testingApiUrl = testingApiUrl ?? "https://localhost:5002";

    console.log(
      `🔧 DatabaseHelper: Worker ${this.workerIndex} → ${this.testingApiUrl} (path-based routing)`
    );
  }

  /**
   * Detects worker index from Playwright's environment variables.
   * Returns null when running outside multi-worker mode.
   */
  private detectWorkerIndex(): number | null {
    const envVar = process.env["TEST_PARALLEL_INDEX"] ?? process.env["TEST_WORKER_INDEX"];
    if (envVar && envVar !== "" && envVar !== "undefined") {
      const parsed = parseInt(envVar, 10);
      if (!isNaN(parsed)) return parsed;
    }
    return null;
  }

  private getWorkerEndpointUrl(path: string): string {
    return `${this.testingApiUrl}/api/testing/${this.workerIndex}${path}`;
  }

  // ── Status ─────────────────────────────────────────────────────────────────

  /** Checks whether the Testing API is available. */
  async getStatus() {
    const response = await this.request.get(`${this.testingApiUrl}/api/testing/status`);
    if (!response.ok()) throw new Error(`Testing API not available: ${response.status()}`);
    return await response.json();
  }

  // ── Reset ──────────────────────────────────────────────────────────────────

  /** Resets BOTH databases (Auth + GestionUsuarios) for this worker. */
  async resetDatabase(): Promise<void> {
    console.log(`♻ [Worker ${this.workerIndex}] Resetting databases…`);
    const response = await this.request.post(this.getWorkerEndpointUrl("/reset-all"));
    if (!response.ok()) throw new Error(`Failed to reset databases: ${await response.text()}`);
    console.log(`✓ [Worker ${this.workerIndex}] Databases reset`);
  }

  // ── Seed ───────────────────────────────────────────────────────────────────

  /** Seeds BOTH databases for this worker with standard fixture data. */
  async seedDatabase(): Promise<void> {
    console.log(`🌱 [Worker ${this.workerIndex}] Seeding databases…`);
    const response = await this.request.post(this.getWorkerEndpointUrl("/seed-all"));
    if (!response.ok()) throw new Error(`Failed to seed databases: ${await response.text()}`);
    console.log(`✓ [Worker ${this.workerIndex}] Databases seeded`);
  }

  // ── Reset + Seed (preferred) ───────────────────────────────────────────────

  /**
   * Resets and seeds BOTH databases in a single HTTP call.
   * This is the preferred method — call it in test.beforeEach.
   *
   * Path: POST /api/testing/{workerIndex}/reset-and-seed-all
   */
  async resetAndSeed(): Promise<void> {
    console.log(`♻🌱 [Worker ${this.workerIndex}] Resetting and seeding databases…`);
    const response = await this.request.post(this.getWorkerEndpointUrl("/reset-and-seed-all"));
    if (!response.ok())
      throw new Error(`Failed to reset and seed databases: ${await response.text()}`);
    console.log(`✓ [Worker ${this.workerIndex}] Databases reset and seeded`);
  }

  // ── Granular (when you only need one service) ──────────────────────────────

  /** Resets ONLY the Auth database. */
  async resetAuthOnly(): Promise<void> {
    console.log("♻ Resetting Auth database only…");
    const response = await this.request.post(`${this.testingApiUrl}/api/testing/auth/reset`);
    if (!response.ok()) throw new Error(`Failed to reset Auth database: ${await response.text()}`);
  }
}
