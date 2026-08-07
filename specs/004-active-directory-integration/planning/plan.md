# Technical Plan — F-004: Active Directory Integration

## Metadata

| Property          | Value                                               |
| ----------------- | --------------------------------------------------- |
| Feature           | F-004 — Active Directory Integration                |
| Scenario          | Backend-only                                        |
| Bounded Context   | IdentitySync (Supporting Domain)                    |
| Bolt              | Bolt 4 — Week 11–12                                 |
| Issue             | gh#5                                                |
| Author            | Bolt Plan Agent                                     |
| Created           | 2026-08-07                                          |
| Status            | Draft                                               |
| Dependencies      | F-001 complete (Employee entity exists); Graph API permissions granted |

---

## Executive Summary

F-004 automates the nightly synchronization of employee, department, and manager data from
**Microsoft Azure Active Directory** via the Microsoft Graph API. The sync runs at 2:00 AM
via a `.NET BackgroundService` using a Managed Identity (no stored credentials). Administrators
can trigger a manual sync via the admin API. The feature also adds sync health monitoring
to the admin panel.

---

## Architecture Context

| Concern | Decision |
|---------|----------|
| Module | `src/Modules/IdentitySync/` |
| Transport | Microsoft.Graph SDK v5 (async, paged) + `DefaultAzureCredential` (Managed Identity) |
| Scheduling | `.NET BackgroundService` with cron (`"0 2 * * *"` — configurable) |
| Concurrency | Redis distributed lock — only one sync job runs at a time (BR-065) |
| Retry | Polly: max 3 attempts, exponential backoff 1s → 5s → 30s per record (AC-012.7) |
| Auth | Managed Identity → MS Graph (`User.Read.All`, `Directory.Read.All`) |
| Rate limit | Max 1 manual sync per hour (BR-067) |

---

## Bolt Breakdown

| Bolt | Scope | Focus | Duration |
|------|-------|-------|----------|
| **4A** | Backend | SyncJob aggregate + Graph API client + upsert logic | 3 days |
| **4B** | Backend | BackgroundService + manual trigger API + monitoring | 4 days |

---

## Bolt 4A — Sync Domain & Graph Client

### Module Structure

```
src/Modules/IdentitySync/
  ├── Domain/
  │   ├── SyncJob.cs                  ← Aggregate Root
  │   ├── SyncError.cs               ← Child Entity
  │   └── ValueObjects/
  │       ├── SyncJobId.cs
  │       ├── SyncJobType.cs         ← Scheduled | Manual
  │       └── SyncJobStatus.cs       ← Running | Completed | CompletedWithErrors | Failed
  ├── Application/
  │   ├── Commands/
  │   │   ├── TriggerScheduledAdSync/
  │   │   │   ├── TriggerScheduledAdSyncCommand.cs
  │   │   │   └── TriggerScheduledAdSyncHandler.cs
  │   │   ├── TriggerManualAdSync/
  │   │   │   ├── TriggerManualAdSyncCommand.cs
  │   │   │   └── TriggerManualAdSyncHandler.cs
  │   │   └── UpsertEmployeeFromAd/
  │   │       ├── UpsertEmployeeFromAdCommand.cs
  │   │       └── UpsertEmployeeFromAdHandler.cs
  │   └── Queries/
  │       ├── GetLastSyncJobStatus/
  │       ├── GetSyncJobHistory/
  │       └── GetSyncJobErrors/
  ├── Infrastructure/
  │   ├── Graph/
  │   │   ├── GraphApiClient.cs       ← wraps Microsoft.Graph SDK
  │   │   ├── AdUserMapper.cs         ← maps AdUserDto → UpsertEmployeeFromAdCommand
  │   │   └── AdUserDto.cs
  │   ├── Persistence/
  │   │   ├── SyncJobRepository.cs
  │   │   └── Configurations/
  │   └── BackgroundServices/
  │       └── AdSyncBackgroundService.cs
  └── Api/
      └── AdSyncEndpoints.cs
```

### Implementation Checklist — Bolt 4A

- [ ] `SyncJob` aggregate — INV-301–304; `RecordError()`, `Complete()`, `Fail()` methods
- [ ] `SyncError` child entity — `RetryCount` tracking; `IsResolved` flag
- [ ] `GraphApiClient.GetAllUsersAsync()` — paged (100 users/page); handles `@odata.nextLink`
- [ ] `GraphApiClient.GetUserManagerAsync(userId)` — resolves manager AD Object ID
- [ ] `GraphApiClient.GetGroupMembersAsync(groupId)` — for role assignment (PM/DM/Admin groups)
- [ ] `AdUserMapper.MapToCommand()` — field mapping per specification in data model
- [ ] `UpsertEmployeeFromAdHandler`:
  - Find by `ExternalAdId` → insert (new) or update (existing)
  - `accountEnabled = false` → set `IsActive = false` (soft-delete, BR-056)
  - Upsert `Department` by name (BR-060)
  - Resolve `ManagerId` from AD manager `objectId` → internal `EmployeeId`
  - Role assignment from AD group membership (BR-058)
- [ ] EF Core migration: `M005_AddAdSyncColumns` (adds `ExternalAdId`, `LastSyncedAt` to existing tables)
- [ ] `SyncJobRepository`: `GetRunningJobAsync()`, `SaveAsync()`, `GetHistoryAsync(days)`
- [ ] Register `Microsoft.Graph` SDK and `DefaultAzureCredential` in DI

---

## Bolt 4B — Background Service & Admin API

### BackgroundService

```csharp
public class AdSyncBackgroundService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly IDistributedLockProvider _lockProvider;
    private readonly SyncScheduleConfig _config;   // "0 2 * * *" from SystemConfig

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            var nextRun = _config.GetNextRunTime(DateTime.UtcNow);
            await Task.Delay(nextRun - DateTime.UtcNow, stoppingToken);

            await using var scope = _scopeFactory.CreateAsyncScope();
            var dispatcher = scope.ServiceProvider.GetRequiredService<ICommandDispatcher>();
            await dispatcher.DispatchAsync(new TriggerScheduledAdSyncCommand(), stoppingToken);
        }
    }
}
```

**Sync execution flow**

```
TriggerScheduledAdSyncCommand
    → Acquire Redis lock "adsync-running" (INV-301)
    → Create SyncJob (Status = Running)
    → GraphApiClient.GetAllUsersAsync()  [paged, 100/page]
    → For each user (parallel, max 10 concurrent):
        → UpsertEmployeeFromAdCommand
        → On error: SyncJob.RecordError(); retry 3x with backoff
    → SyncJob.Complete(created, updated, deactivated, errorCount)
    → Release Redis lock
    → Publish SyncJobCompleted event
    → If errorRate > 5%: publish alert for F-006
```

### Admin API Endpoints

| Method | Route | Handler | Auth |
|--------|-------|---------|------|
| `POST` | `/api/admin/ad-sync/trigger` | `TriggerManualAdSyncHandler` | `RequireAdministrator` |
| `GET` | `/api/admin/ad-sync/status` | `GetLastSyncJobStatusHandler` | `RequireAdministrator` |
| `GET` | `/api/admin/ad-sync/history` | `GetSyncJobHistoryHandler` | `RequireAdministrator` |
| `GET` | `/api/admin/ad-sync/{jobId}/errors` | `GetSyncJobErrorsHandler` | `RequireAdministrator` |

**Manual sync response**

```csharp
record TriggerManualAdSyncResponse(
    Guid JobId,
    string Message   // "Sync started" or "Sync already running" or "Rate limit: try again in X min"
);
```

### OTel Instrumentation

```csharp
// Metrics emitted per sync job (Azure Monitor custom metrics):
_meter.CreateHistogram<double>("adsync.job.duration.seconds")
_meter.CreateCounter<int>("adsync.employees.processed")
_meter.CreateCounter<int>("adsync.employees.created")
_meter.CreateCounter<int>("adsync.employees.updated")
_meter.CreateCounter<int>("adsync.employees.deactivated")
_meter.CreateCounter<int>("adsync.employees.errors")
```

---

## Test Strategy

| Type | Key Scenarios |
|------|---------------|
| Domain Unit | `SyncJob.RecordError()` — error count incremented; max errors tracked |
| Domain Unit | `SyncJob` status transitions: Running → Completed / Failed |
| Application Unit | `UpsertEmployeeFromAdHandler` — new employee created with default Employee role |
| Application Unit | `UpsertEmployeeFromAdHandler` — `accountEnabled=false` → `IsActive = false` |
| Application Unit | `UpsertEmployeeFromAdHandler` — department change updates `DepartmentId` |
| Application Unit | `TriggerManualAdSyncHandler` — rate limit enforced (second trigger within 1 hour → 429) |
| Application Unit | `TriggerManualAdSyncHandler` — duplicate running job → returns existing job ID |
| Integration | `GraphApiClient` with WireMock — paged response with 3 pages of 100 users |
| Integration | `GraphApiClient` with WireMock — simulated API timeout → retry 3x |
| Integration | Full sync: 10 employees upserted; DB verified after sync |
| BDD | AC-012.1 `@smoke` — sync job starts at scheduled time |
| BDD | AC-012.2 `@smoke` — new employees created with Active status |
| BDD | AC-012.6 `@smoke` — summary log written after job |
| BDD | AC-014.1 `@smoke` — admin triggers manual sync |

---

## Quality Gates

| Gate | Threshold |
|------|-----------|
| Line coverage | ≥ 80% |
| Linting | 0 errors |
| Architecture | All NetArchTest rules pass |
| BDD `@smoke` | 100% |
| Sync performance | < 30 min for 500 employees (measured in integration test with WireMock) |
| SAST | 0 Critical (Managed Identity used; no secrets) |

---

## Risks & Mitigations

| Risk | Prob | Impact | Mitigation |
|------|------|--------|------------|
| Graph API permissions not granted before Bolt 4A | High | High | Raise access request in Week 1; use WireMock for all dev/test |
| Graph API rate limiting (10k requests/10 min) | Low | Medium | 500 employees = ~600 calls; well under limit; add retry on 429 |
| AD department name changes between sync runs | Medium | Medium | Upsert by name; existing department gets renamed; no orphan created |
| Manager chain resolution — manager not yet processed in same batch | Medium | Medium | Two-pass approach: first pass upserts all users; second pass resolves managers |
| WireMock test data drifts from real Graph API schema | Low | Medium | Validate WireMock responses against Microsoft Graph JSON schema once |

---

## Dependencies

| Dependency | Type | Status |
|-----------|------|--------|
| F-001 — `Employee`, `Department`, `Project` entities in DB | Hard | Blocks Bolt 4A |
| Microsoft Graph API permissions granted (Managed Identity) | Hard | Request in Phase 0; required before Bolt 4B prod deploy |
| Redis (for distributed lock) | Hard | Phase 4 infrastructure |
| AD Groups created: `VacationSystem-ProjectManagers`, `VacationSystem-DepartmentManagers`, `VacationSystem-Admins` | Hard | IT admin action; required for role assignment |

---

## Open Research Items

| Item | Priority | Owner |
|------|----------|-------|
| Q-010: Are projects defined in AD groups or managed manually? | High | IT Admin / PO |
| Q-011: How are Department Managers identified in AD (title / group / manager chain)? | High | IT Admin |
| Q-012: Should terminated employees' historical vacation data be preserved? | Resolved | Yes — soft delete only (BR-056) |
