# Task List — F-005: ServiceNow Integration

## Metadata

| Property       | Value                                               |
| -------------- | --------------------------------------------------- |
| Feature        | F-005 — ServiceNow Integration                      |
| Scenario       | Backend-only                                        |
| Source plan    | `planning/plan.md`                                  |
| Gherkin source | `tests/vacation-export.feature` · `tests/balance-import-and-monitoring.feature` |
| Steps stub     | `tests/ServiceNowIntegration.ReqnrollTests/StepDefinitions/ServiceNowIntegrationSteps.cs` |
| Created        | 2026-08-07                                          |
| Status         | Ready for execution                                 |

---

## Reconciliation plan ↔ Gherkin

### Coverage

| Metric | Count |
|--------|-------|
| Endpoints planned | 4 (export status, failed records, retry, history) |
| Endpoints with BDD coverage | 4 |
| `@smoke` scenarios | 6 (3 export + 3 import/monitoring) |
| `@smoke` with planned implementation | 6 |
| Gaps | 0 |

### Gaps detected

- **No gaps.** All `@smoke` scenarios in both `.feature` files have corresponding planned tasks.
- `Q-013` (ServiceNow table name and field mapping) is still open — **T004 depends on this being resolved** before coding the HTTP client. WireMock schema must be confirmed against real ServiceNow API before UAT.
- Step definitions stub → **T021** in Bolt 5B.

---

## Auto-Split Log

| Original Bolt | Decision | Reason |
|--------------|----------|--------|
| Bolt 5A (export engine) | **Split → Bolt 5A + Bolt 5B** | 11 tasks > 8-task limit |
| Bolt 5B (import + admin) | Kept; 8 tasks | Weight 3.5L ≤ 5L |

---

## User Story → Bolt Map

| User Story | Priority | Bolt |
|-----------|---------|------|
| US-016 Nightly Vacation Export | P1 | Bolt 5A + 5B |
| US-017 Employee Balance Import | P1 | Bolt 5B |
| US-018 Export Monitoring & Error Recovery | P2 | Bolt 5B |

---

## Bolt 5A — ServiceNow HTTP Client, Export Domain & Export Engine

**Goal:** Domain aggregates, typed HTTP client with Polly, `TriggerNightlyExportHandler`.
**Duration:** 3 days · **Weight:** 4.5L equivalent

### Domain

- [ ] T001 [S] Create `src/Modules/ServiceNowIntegration/` folder structure
- [ ] T002 [M] [US-016] Implement `ExportJob` aggregate root: `AddRecord()`, `RecordSuccess()`, `RecordFailure()`, `Complete()`, `Fail()`, `INV-401–404`
- [ ] T003 [M] [US-016] Implement `ExportRecord` child entity: `Retry()` (returns `false` at `RetryCount >= 3`); `ExportAction` enum (Create/Update/Delete); `ExportRecordStatus` enum
- [ ] T004 [M] [US-017] Implement `ImportJob` aggregate root; `ImportJobStatus` enum

### Infrastructure — HTTP Client

- [ ] T005 [L] [US-016] Implement `ServiceNowHttpClient` (typed `HttpClient`): Polly retry policy (3×, backoff 1s→5s→30s with jitter); circuit breaker (5 failures → open 60s); 10s per-call timeout; `ServiceNowAuthHandler` `DelegatingHandler` reads API key from Key Vault on startup (cached; refreshes on 401)
- [ ] T006 [M] [US-016] Implement `VacationExportMapper.MapToServiceNowDto()` — per field-mapping table in data model (⚠ depends on Q-013 being answered)

### Application — Export Command

- [ ] T007 [L] [US-016] `TriggerNightlyExportHandler`: acquire Redis lock `sn-export-running`; delta query (Approved + IsExported=false → Create action; IsExported=true + Cancelled → Delete action; BR-071–073); POST/DELETE per record; `RecordSuccess(serviceNowId)` / `RecordFailure(error)`; `ExportJob.Complete()`; publish `ExportJobCompleted`; alert if errorRate > 5% (BR-081)

### Persistence

- [ ] T008 [M] [P] EF Core config for `ExportJob` + `ExportRecord`; migration `M006_AddServiceNowExportColumns` (adds `IsExported`, `ExportedAt`, `ServiceNowRecordId`, `LastExportedAt` to `VACATION_REQUESTS`); indexes `IX_ER_RequestId`, `IX_VR_IsExported_Status`

### Tests

- [ ] T009 [M] [US-016] xUnit: `ExportJob` — `RecordSuccess` increments `TotalExported`; `RecordFailure` increments `ErrorCount`; `Complete()` sets terminal state
- [ ] T010 [M] [US-016] xUnit: `ExportRecord.Retry()` returns `false` at `RetryCount = 3` (MaxRetriesExceeded)
- [ ] T011 [M] [US-016] xUnit + WireMock.NET: `ServiceNowHttpClient` POST → returns sys_id; record marked exported; Polly retry (503 twice → success on 3rd); circuit breaker opens on 5 failures

### Quality Gates — Bolt 5A

- [ ] T012-QG `dotnet build --warnaserror` → 0 warnings
- [ ] T013-QG `dotnet test` → 100% pass
- [ ] T014-QG Coverlet line ≥ 80% / branch ≥ 75%
- [ ] T015-QG `dotnet stryker --project ServiceNowIntegration.Domain.csproj` → ≥ 70%
- [ ] T016-QG SAST: API key read from Key Vault only — 0 hardcoded secrets

---

## Bolt 5B — Balance Import, BackgroundServices, Admin API & Steps

**Goal:** Import engine, both BackgroundServices (export 4AM + import 6AM), admin monitoring endpoints.
**Duration:** 3 days · **Weight:** 3.5L equivalent

### Application — Balance Import

- [ ] T017 [M] [US-017] `TriggerNightlyBalanceImportHandler`: acquire Redis lock `sn-import-running`; `GET /api/now/table/u_vacation_balances` (paged); match by `ExternalAdId` or email fallback; update `Employee.VacationTotalDays`, `VacationUsedDays`, `BalanceUpdatedAt`; circuit-breaker open → skip + warn (BR-078); publish `ImportJobCompleted`
- [ ] T018 [M] [US-016] `BalanceImportMapper.MapToVacationBalance()` — ServiceNow balance response → `VacationBalance` VO fields (depends on Q-013)

### BackgroundServices

- [ ] T019 [L] [US-016][US-017] `ExportBackgroundService` (cron `"0 4 * * *"`) + `ImportBackgroundService` (cron `"0 6 * * *"`): both use scoped DI; Redis locks; OTel metrics (`sn.export.duration`, `sn.import.duration`, error counts); `ExportBackgroundService` waits 60s after 4:00 AM to ensure AD sync is done

### Admin API

- [ ] T020 [M] [US-018] `ServiceNowAdminEndpoints` (4 routes): `GET /api/admin/servicenow/export/status`, `GET /api/admin/servicenow/export/failed`, `POST /api/admin/servicenow/export/{recordId}/retry` (resets `RetryCount`; BR-082), `GET /api/admin/servicenow/export/history` — all `RequireAdministrator`

### Queries

- [ ] T021 [S] `GetLastExportJobStatusQuery`, `GetFailedExportRecordsQuery`, `GetExportJobHistoryQuery` (30 days) — Dapper

### BDD Step Definitions

- [ ] T022 [M] [P] Implement `ServiceNowIntegrationSteps.cs` body methods for `vacation-export.feature` and `balance-import-and-monitoring.feature`

### Tests

- [ ] T023 [M] [P] xUnit + WireMock: `TriggerNightlyExportHandler` full batch — 3 approved→Create; 1 cancelled-previously-exported→Delete; 1 API failure→MaxRetriesExceeded; other records continue (BR-075)
- [ ] T024 [M] [P] xUnit: `TriggerNightlyBalanceImportHandler` — 500 employees balances updated; circuit-breaker open → import skipped, stale balance preserved; `BalanceUpdatedAt` set correctly
- [ ] T025 [S] xUnit: `RetryExportRecordHandler` resets `RetryCount`; re-queues for export

### Quality Gates — Bolt 5B

- [ ] T026-QG `dotnet build --warnaserror` → 0 warnings
- [ ] T027-QG `dotnet test` → 100% pass
- [ ] T028-QG Coverlet line ≥ 80% / branch ≥ 75%
- [ ] T029-QG Export batch performance: integration test (WireMock, 50 records) completes < 15 min
- [ ] T030-QG Import performance: 500 balances updated < 10 min
- [ ] T031-QG NetArchTest → all rules pass
- [ ] T032-QG SAST → 0 Critical findings
