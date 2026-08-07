# Technical Plan — F-005: ServiceNow Integration

## Metadata

| Property          | Value                                               |
| ----------------- | --------------------------------------------------- |
| Feature           | F-005 — ServiceNow Integration                      |
| Scenario          | Backend-only                                        |
| Bounded Context   | ServiceNowIntegration (Supporting Domain)           |
| Bolt              | Bolt 5 — Week 13–14                                 |
| Issue             | gh#6                                                |
| Author            | Bolt Plan Agent                                     |
| Created           | 2026-08-07                                          |
| Status            | Draft                                               |
| Dependencies      | F-001 + F-002 complete (Approved requests available); F-004 complete (Employee entities) |

---

## Executive Summary

F-005 automates the **nightly export of fully-approved vacation requests to ServiceNow** and the
**import of vacation balance data** from ServiceNow. The export runs at 4:00 AM (after AD sync);
the import runs at 6:00 AM. Both jobs are delta-based (only changed records) and implement
Polly retry + circuit-breaker patterns against the ServiceNow Table API.

---

## Architecture Context

| Concern | Decision |
|---------|----------|
| Module | `src/Modules/ServiceNowIntegration/` |
| Transport | HttpClient + Polly (retry: 3 attempts; backoff 1s → 5s → 30s; circuit breaker: 5 failures = open) |
| Auth | API key or OAuth 2.0 Client Credentials stored in **Azure Key Vault** (Managed Identity access) |
| Scheduling | `.NET BackgroundService` — export at 4:00 AM, import at 6:00 AM |
| Concurrency | Redis distributed lock per job type |
| Delta logic | Export: `VacationRequest.IsExported = false` AND `Status = Approved`; OR `IsExported = true` AND `Status = Cancelled` |

---

## Bolt Breakdown

| Bolt | Scope | Focus | Duration |
|------|-------|-------|----------|
| **5A** | Backend | ExportJob aggregate + ServiceNow HTTP client + export BackgroundService | 3 days |
| **5B** | Backend | ImportJob + balance import BackgroundService + admin monitoring API | 4 days |

---

## Bolt 5A — Export Engine

### Module Structure

```
src/Modules/ServiceNowIntegration/
  ├── Domain/
  │   ├── ExportJob.cs                ← Aggregate Root
  │   ├── ExportRecord.cs             ← Child Entity
  │   ├── ImportJob.cs                ← Aggregate Root
  │   └── ValueObjects/
  │       ├── ExportJobId.cs
  │       ├── ExportAction.cs         ← Create | Update | Delete
  │       ├── ExportJobStatus.cs
  │       ├── ExportRecordStatus.cs
  │       └── ServiceNowRecordId.cs
  ├── Application/
  │   ├── Commands/
  │   │   ├── TriggerNightlyExport/
  │   │   ├── TriggerNightlyBalanceImport/
  │   │   └── RetryExportRecord/
  │   └── Queries/
  │       ├── GetLastExportJobStatus/
  │       ├── GetFailedExportRecords/
  │       └── GetExportJobHistory/
  ├── Infrastructure/
  │   ├── Http/
  │   │   ├── ServiceNowHttpClient.cs          ← typed HttpClient
  │   │   ├── ServiceNowAuthHandler.cs         ← adds API key from Key Vault
  │   │   ├── VacationExportMapper.cs          ← VacationRequest → ServiceNow DTO
  │   │   └── BalanceImportMapper.cs           ← ServiceNow DTO → VacationBalance
  │   ├── Persistence/
  │   │   ├── ExportJobRepository.cs
  │   │   └── ImportJobRepository.cs
  │   └── BackgroundServices/
  │       ├── ExportBackgroundService.cs
  │       └── ImportBackgroundService.cs
  └── Api/
      └── ServiceNowAdminEndpoints.cs
```

### Implementation Checklist — Bolt 5A

- [ ] `ExportJob` aggregate — INV-401–404; `AddRecord()`, `RecordSuccess()`, `RecordFailure()`, `Complete()`
- [ ] `ExportRecord.Retry()` — returns `false` when `RetryCount >= 3` (MaxRetriesExceeded)
- [ ] `ServiceNowHttpClient` — typed `HttpClient` registered with Polly:
  - Retry policy: 3 attempts, `ExponentialBackoff(1s, 5s, 30s)`
  - Circuit breaker: 5 consecutive failures → open for 60 seconds
  - Timeout: 10s per request
- [ ] `ServiceNowAuthHandler` — `DelegatingHandler` that reads API key from Key Vault on startup (cached, refreshed on 401)
- [ ] `VacationExportMapper.MapToServiceNowDto()` — field mapping per specification in data model
- [ ] `TriggerNightlyExportHandler`:
  1. Acquire Redis lock `"sn-export-running"`
  2. Create `ExportJob`
  3. Query: approved + not exported (Create action)
  4. Query: previously exported + now cancelled (Delete action)
  5. For each record: POST/DELETE to ServiceNow; handle success/failure
  6. Mark `VacationRequest.IsExported = true` + store `ServiceNowRecordId`
  7. `ExportJob.Complete()`; release lock
- [ ] EF Core migration: `M006_AddServiceNowExportColumns` (`IsExported`, `ExportedAt`, `ServiceNowRecordId`, `LastExportedAt` on `VACATION_REQUESTS`)
- [ ] OTel instrumentation: `sn.export.duration`, `sn.export.total`, `sn.export.errors`

---

## Bolt 5B — Import Engine & Admin API

### Balance Import Flow

```
TriggerNightlyBalanceImportCommand
    → Acquire Redis lock "sn-import-running"
    → Create ImportJob (Status = Running)
    → GET /api/now/table/u_vacation_balances?active=true (paged)
    → For each record:
        → Find Employee by ExternalAdId (or email fallback)
        → Update Employee.VacationTotalDays, VacationUsedDays, BalanceUpdatedAt
        → On error: log ImportError; continue batch (BR-075)
    → ImportJob.Complete()
    → Release lock
    → Publish ImportJobCompleted event
```

**Fallback on ServiceNow unavailable (BR-078)**

```csharp
// Circuit breaker open → skip import; log warning; use stale balance data
// Employee.VacationBalance remains from previous successful import
// BalanceUpdatedAt shown in UI with "last updated: X days ago" (BR-079)
```

### Admin API Endpoints

| Method | Route | Handler | Auth |
|--------|-------|---------|------|
| `GET` | `/api/admin/servicenow/export/status` | `GetLastExportJobStatusHandler` | `RequireAdministrator` |
| `GET` | `/api/admin/servicenow/export/failed` | `GetFailedExportRecordsHandler` | `RequireAdministrator` |
| `POST` | `/api/admin/servicenow/export/{recordId}/retry` | `RetryExportRecordHandler` | `RequireAdministrator` |
| `GET` | `/api/admin/servicenow/export/history` | `GetExportJobHistoryHandler` | `RequireAdministrator` |

**Failed export record DTO**

```csharp
record FailedExportRecordDto(
    Guid RecordId,
    Guid RequestId,
    string EmployeeName,
    DateOnly StartDate,
    DateOnly EndDate,
    string ErrorMessage,
    int RetryCount,
    DateTime LastAttemptAt
);
```

---

## Test Strategy

| Type | Key Scenarios |
|------|---------------|
| Domain Unit | `ExportJob` — `RecordSuccess()` increments `TotalExported` |
| Domain Unit | `ExportRecord.Retry()` — returns `false` at `RetryCount = 3` |
| Application Unit | `TriggerNightlyExportHandler` — delta query returns only non-exported approved requests |
| Application Unit | `TriggerNightlyExportHandler` — cancelled previously-exported request triggers Delete action |
| Application Unit | `RetryExportRecordHandler` — resets `RetryCount`; re-attempts export (BR-082) |
| Integration | `ServiceNowHttpClient` with WireMock — POST returns `sys_id`; record marked exported |
| Integration | Retry policy — WireMock returns 503 twice, succeeds on 3rd attempt |
| Integration | Circuit breaker — 5 failures open circuit; 6th call skipped; closed after 60s |
| Integration | Balance import — 500 employees updated with balance data |
| BDD | AC-016.1 `@smoke` — export job queries approved unexported requests |
| BDD | AC-016.2 `@smoke` — records POSTed to ServiceNow Table API |
| BDD | AC-016.3 `@smoke` — request marked exported after success |
| BDD | AC-017.1 `@smoke` — balance import fetches data for all active employees |
| Performance | Export batch: < 15 min for 50 records (k6 / integration test with simulated latency) |

---

## Quality Gates

| Gate | Threshold |
|------|-----------|
| Line coverage | ≥ 80% |
| Linting | 0 errors |
| Architecture | All NetArchTest rules pass |
| BDD `@smoke` | 100% |
| Export batch duration | < 15 min for 50 records |
| SAST | 0 Critical (Key Vault used; no credentials in code or config) |

---

## Risks & Mitigations

| Risk | Prob | Impact | Mitigation |
|------|------|--------|------------|
| ServiceNow sandbox not available before Bolt 5A | High | High | All dev/test uses WireMock; production credentials requested in Week 1 |
| ServiceNow rate limits block batch export | Medium | Medium | Add `Thread.Sleep(100ms)` between records; use bulk API if available |
| ServiceNow table/field names unknown (Q-013) | High | High | Resolve with ServiceNow team before Bolt 5A starts; WireMock uses confirmed schema |
| Export runs before AD sync completes (timing issue) | Low | Medium | Check: `ExportBackgroundService` waits 60s after 4:00 AM before starting |
| Balance import uses stale data in submission validation | Low | Medium | Display `BalanceUpdatedAt` in UI; accept stale balance if import failed (BR-078) |

---

## Dependencies

| Dependency | Type | Status |
|-----------|------|--------|
| F-001 + F-002 — Approved `VacationRequest` records exist | Hard | Blocks Bolt 5A |
| F-004 — `Employee.ExternalAdId` populated (needed for balance import matching) | Hard | Blocks Bolt 5B |
| ServiceNow Table API access + sandbox credentials | Hard | Request in Phase 0 |
| Azure Key Vault with ServiceNow API key secret | Hard | Platform Engineer; Phase 4 |

---

## Open Research Items

| Item | Priority | Owner |
|------|----------|-------|
| Q-013: ServiceNow table name and exact field mapping | Critical | ServiceNow Admin |
| Q-014: ServiceNow rate limits (requests per minute?) | High | ServiceNow Admin |
| Q-015: Queue exports if ServiceNow is down at 4:00 AM? | Medium | PO decision (BR-078 says skip + alert) |
