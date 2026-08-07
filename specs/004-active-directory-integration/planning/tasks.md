# Task List — F-004: Active Directory Integration

## Metadata

| Property       | Value                                               |
| -------------- | --------------------------------------------------- |
| Feature        | F-004 — Active Directory Integration                |
| Scenario       | Backend-only                                        |
| Source plan    | `planning/plan.md`                                  |
| Gherkin source | `tests/employee-synchronization.feature` · `tests/manual-sync-trigger.feature` |
| Steps stub     | `tests/IdentitySync.ReqnrollTests/StepDefinitions/AdSyncSteps.cs` |
| Created        | 2026-08-07                                          |
| Status         | Ready for execution                                 |

---

## Reconciliation plan ↔ Gherkin

### Coverage

| Metric | Count |
|--------|-------|
| Endpoints planned | 4 (trigger, status, history, errors) |
| Endpoints with BDD coverage | 4 |
| `@smoke` scenarios | 6 (3 sync + 3 admin) |
| `@smoke` with planned implementation | 6 |
| Gaps | 1 (notable) |

### Gaps detected

- **Notable gap:** US-013 (Organizational Hierarchy Sync — AC-013.1–013.5) has no `.feature` file. The plan documents it but BDD coverage is missing. → **T019 added**: "Create `hierarchy-sync.feature` Gherkin + implement `AdSyncSteps` for hierarchy scenarios." This is explicitly called out since hierarchy drives correct approval routing.
- Step definitions stub → **T020** in Bolt 4B.

---

## Auto-Split Log

| Original Bolt | Decision | Reason |
|--------------|----------|--------|
| Bolt 4A (Graph + domain) | **Split → Bolt 4A + Bolt 4B** | 12 tasks > 8-task limit |
| Bolt 4B (BackgroundService + API) | Kept; 8 tasks on the limit | Weight 3.75L ≤ 5L |

---

## User Story → Bolt Map

| User Story | Priority | Bolt |
|-----------|---------|------|
| US-012 Nightly Employee Synchronization | P1 | Bolt 4A + 4B |
| US-013 Organizational Hierarchy Sync | P1 | Bolt 4A + 4B |
| US-014 Manual Sync Trigger | P2 | Bolt 4B |
| US-015 Sync Monitoring & Alerting | P2 | Bolt 4B |

---

## Bolt 4A — IdentitySync Domain, Graph Client & Upsert

**Goal:** Domain aggregate, Microsoft Graph SDK integration, `UpsertEmployeeFromAdHandler`.
**Duration:** 3 days · **Weight:** 4.5L equivalent

### Domain

- [ ] T001 [S] Create `src/Modules/IdentitySync/` folder structure
- [ ] T002 [M] [US-012] Implement `SyncJob` aggregate root: `RecordError()`, `Complete(counts)`, `Fail(reason)`, `Duration()`, `INV-301–304`
- [ ] T003 [M] [US-012] Implement `SyncError` child entity (`RetryCount`, `IsResolved`); `SyncJobType` + `SyncJobStatus` enums

### Infrastructure — Graph API

- [ ] T004 [L] [US-012] Implement `GraphApiClient`: `GetAllUsersAsync()` (cursor-based paging, 100 users/page; handles `@odata.nextLink`), `GetUserManagerAsync(userId)`, `GetGroupMembersAsync(groupId)` — uses `DefaultAzureCredential` (Managed Identity; no stored secrets)
- [ ] T005 [M] [US-012][US-013] Implement `AdUserMapper.MapToCommand()` per field-mapping specification in data model; role assignment from AD group membership (BR-058)

### Application — Commands

- [ ] T006 [L] [US-012][US-013] Implement `UpsertEmployeeFromAdHandler`: two-pass strategy (pass 1: upsert all users; pass 2: resolve `ManagerId` from `ExternalAdId`); upsert `Department` by name; `accountEnabled=false` → `IsActive=false` (BR-056); parallel processing max 10 concurrent with `SemaphoreSlim`
- [ ] T007 [M] [US-012] `TriggerScheduledAdSyncCommand` + handler: acquire Redis lock `adsync-running`; create `SyncJob`; call `GraphApiClient.GetAllUsersAsync()`; for each user dispatch `UpsertEmployeeFromAdCommand` with Polly retry (3× exp backoff: 1s→5s→30s); `SyncJob.Complete()`; publish `SyncJobCompleted`; alert if errorRate > 5% (BR-069)

### Persistence

- [ ] T008 [M] [P] EF Core config for `SyncJob` + `SyncError`; migration `M005_AddAdSyncColumns` (adds `ExternalAdId`, `LastSyncedAt` to `EMPLOYEES` and `DEPARTMENTS`); indexes `IX_EMP_ExternalAdId`, `IX_SJ_Status_StartedAt`

### Tests

- [ ] T009 [M] [US-012] xUnit: `SyncJob` status transitions; `RecordError()` increments count; `Complete()` sets terminal state
- [ ] T010 [M] [US-012] xUnit + WireMock.NET: `GraphApiClient` paged response (3 pages × 100 users); simulated 503 → Polly retry; `AdUserMapper` field mapping correctness
- [ ] T011 [M] [US-012][US-013] xUnit: `UpsertEmployeeFromAdHandler` — new employee created with `Employee` role default; `accountEnabled=false` → `IsActive=false` (soft-delete only); department change updates `DepartmentId`; manager resolution second pass

### Quality Gates — Bolt 4A

- [ ] T012-QG `dotnet build --warnaserror` → 0 warnings
- [ ] T013-QG `dotnet test` → 100% pass
- [ ] T014-QG Coverlet line ≥ 80% / branch ≥ 75%
- [ ] T015-QG `dotnet stryker --project IdentitySync.Application.csproj` → ≥ 70%

---

## Bolt 4B — BackgroundService, Admin API & Monitoring

**Goal:** Scheduled and manual sync execution, admin monitoring endpoints, hierarchy Gherkin gap fix.
**Duration:** 3 days · **Weight:** 3.75L equivalent

### Application — Manual Trigger & Hierarchy

- [ ] T016 [M] [US-014] `TriggerManualAdSyncCommand` + handler: INV-301 concurrent-job guard (Redis lock); INV-302 rate-limit check (1 per hour; BR-067); Admin-only auth; returns existing job ID if running (AC-014.3)
- [ ] T017 [M] [US-013] Extend `UpsertEmployeeFromAdHandler` to upsert `Department` from `user.department`; derive DM from highest-level manager attribute (BR-062); `IX_DEPT_ExternalAdId` for fast lookup

### Hierarchy Gherkin Gap Fix

- [ ] T018 [M] [US-013] Add `hierarchy-sync.feature` (AC-013.1–013.5): department created/updated; manager relationships derived; inactive department preserved; pending requests keep original approvers (BR-063)
- [ ] T019 [S] [US-013] Add hierarchy scenarios to `AdSyncSteps.cs` body implementations

### BackgroundService

- [ ] T020 [L] [US-012] `AdSyncBackgroundService`: cron-based scheduling from `SystemConfiguration` (`adsync.schedule_cron`, default `"0 2 * * *"`); scoped DI for command dispatch; Redis distributed lock prevents parallel runs; OTel metrics (`adsync.job.duration`, `adsync.employees.processed`, `adsync.employees.errors`)

### Admin API

- [ ] T021 [M] [US-014][US-015] `AdSyncEndpoints` (4 routes): `POST /api/admin/ad-sync/trigger`, `GET /api/admin/ad-sync/status`, `GET /api/admin/ad-sync/history`, `GET /api/admin/ad-sync/{jobId}/errors` — all `RequireAdministrator`

### Queries

- [ ] T022 [S] `GetLastSyncJobStatusQuery`, `GetSyncJobHistoryQuery` (last 30 days), `GetSyncJobErrorsQuery` — all Dapper

### BDD Step Definitions

- [ ] T023 [M] [P] Implement `AdSyncSteps.cs` body methods for `employee-synchronization.feature`, `manual-sync-trigger.feature`, and new `hierarchy-sync.feature`

### Tests

- [ ] T024 [M] [P] xUnit: `TriggerManualAdSyncCommand` rate-limit enforced (second trigger within 60 min → 429); concurrent-job guard (second trigger while running → 409); Admin-only auth
- [ ] T025 [M] [P] xUnit + WireMock: full sync — 10 employees upserted; hierarchy resolved; DB state verified after completion; error rate > 5% → alert event published

### Quality Gates — Bolt 4B

- [ ] T026-QG `dotnet build --warnaserror` → 0 warnings
- [ ] T027-QG `dotnet test` → 100% pass (including hierarchy scenarios)
- [ ] T028-QG Coverlet line ≥ 80% / branch ≥ 75%
- [ ] T029-QG Sync performance: integration test (WireMock, 500-user set) completes < 30 min
- [ ] T030-QG SAST: `DefaultAzureCredential` used — 0 hardcoded secrets findings
- [ ] T031-QG NetArchTest → all rules pass
