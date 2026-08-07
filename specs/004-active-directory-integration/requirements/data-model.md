# Domain Model — F-004: Active Directory Integration

## Metadata

| Property        | Value                                                 |
| --------------- | ----------------------------------------------------- |
| Feature         | F-004 — Active Directory Integration                  |
| Bounded Context | IdentitySync (Supporting Domain)                      |
| Source          | UC-012 · UC-013 · UC-014 · UC-015 · US-012–015       |
| Created         | 2026-08-07                                            |
| Author          | Bolt DDD Agent                                        |
| Status          | Draft                                                 |

---

## Bounded Context Overview

:::mermaid
flowchart TB
    subgraph IS["🔵 IdentitySync (Supporting Domain)"]
        SJ["SyncJob\n(Aggregate Root)"]
        SE["SyncError\n(Child Entity)"]
        SJ -->|owns| SE
    end

    subgraph ORG["🔵 Organization (Supporting)"]
        EMP["Employee\n(Aggregate Root — updated by sync)"]
        DEPT["Department\n(Entity — created/updated by sync)"]
        PROJ["Project\n(Entity — created/updated by sync)"]
    end

    subgraph AD["☁️ Azure Active Directory (External)"]
        GRAPH["Microsoft Graph API\n(User.Read.All, Directory.Read.All)"]
    end

    subgraph MON["📊 Azure Monitor"]
        OTel["OTel Metrics\n(sync health, error rate)"]
    end

    GRAPH -->|"nightly at 2:00 AM\n(BackgroundService)"| SJ
    SJ -->|upserts| EMP
    SJ -->|upserts| DEPT
    SJ -->|derives hierarchy| PROJ
    IS -->|publishes metrics| OTel

    style IS fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    style ORG fill:#e3f2fd,stroke:#1565c0,stroke-width:1px
    style AD fill:#f1f8e9,stroke:#558b2f,stroke-width:1px
    style MON fill:#fce4ec,stroke:#880e4f,stroke-width:1px
:::

---

## Aggregate Model

:::mermaid
classDiagram
    class SyncJob {
        +SyncJobId Id
        +SyncJobType Type
        +SyncJobStatus Status
        +DateTime StartedAt
        +DateTime? CompletedAt
        +int TotalProcessed
        +int Created
        +int Updated
        +int Deactivated
        +int ErrorCount
        +string? TriggeredBy
        +IReadOnlyList~SyncError~ Errors
        +RecordError(externalId, message, retryCount)
        +Complete(counts)
        +Fail(reason)
        +Duration() TimeSpan?
    }

    class SyncError {
        +SyncErrorId Id
        +SyncJobId JobId
        +string EmployeeExternalId
        +string ErrorMessage
        +int RetryCount
        +bool IsResolved
        +DateTime CreatedAt
    }

    class SyncJobType {
        <<Enumeration>>
        Scheduled
        Manual
    }

    class SyncJobStatus {
        <<Enumeration>>
        Running
        Completed
        CompletedWithErrors
        Failed
    }

    class AdUserDto {
        <<External DTO — Graph API>>
        +string Id
        +string DisplayName
        +string GivenName
        +string Surname
        +string Mail
        +string Department
        +string JobTitle
        +AdUserDto? Manager
        +bool AccountEnabled
    }

    SyncJob "1" *-- "0..*" SyncError : owns
    SyncJob --> SyncJobType : type
    SyncJob --> SyncJobStatus : status
:::

---

## Entity Definitions

### SyncJob _(Aggregate Root)_

Records the execution and outcome of a single AD synchronization run (scheduled or manual).
Acts as the authoritative audit record for every sync operation. Retained for 90 days (BR-068).

| Property | Type | Constraints |
|----------|------|-------------|
| `Id` | `SyncJobId` | Required, unique, GUID-based |
| `Type` | `SyncJobType` | `Scheduled` or `Manual` |
| `Status` | `SyncJobStatus` | `Running → Completed / CompletedWithErrors / Failed` |
| `StartedAt` | `DateTime` (UTC) | Set on job start; immutable |
| `CompletedAt` | `DateTime?` (UTC) | Set on completion |
| `TotalProcessed` | `int` | Total AD records fetched |
| `Created` | `int` | New employees added |
| `Updated` | `int` | Existing employees modified |
| `Deactivated` | `int` | Employees soft-deleted |
| `ErrorCount` | `int` | Records that failed after max retries |
| `TriggeredBy` | `string?` | `"Scheduler"` or admin `EmployeeId` (for manual) |
| `Errors` | `IReadOnlyList<SyncError>` | Child entities; individual failures |

**Invariants**

| # | Invariant | Source |
|---|-----------|--------|
| INV-301 | Only one `Running` sync job at any time (mutex) | BR-065 |
| INV-302 | Manual sync: max 1 trigger per hour (rate limit) | BR-067 |
| INV-303 | Job status transitions only forward (cannot go back to `Running`) | Domain rule |
| INV-304 | `CompletedAt` must be set when status is terminal | Domain rule |

---

### SyncError _(Child Entity of SyncJob)_

Represents a single employee record that failed to sync. Stored with the retry count so the
background service can retry up to 3 times with exponential backoff.

| Property | Type | Constraints |
|----------|------|-------------|
| `Id` | `SyncErrorId` | Required, unique, GUID-based |
| `JobId` | `SyncJobId` | Required, FK to parent `SyncJob` |
| `EmployeeExternalId` | `string` | AD Object ID of the failing employee |
| `ErrorMessage` | `string` | Error details for admin troubleshooting |
| `RetryCount` | `int` | 0–3; job fails employee after 3 attempts (BR-007) |
| `IsResolved` | `bool` | `true` after successful retry |
| `CreatedAt` | `DateTime` (UTC) | When the error occurred |

---

## AD → Domain Mapping

The following table defines how Microsoft Graph API fields map to the internal domain model.
This is the authoritative field-mapping specification for the sync implementation.

| Graph API Field | Internal Entity | Internal Property | Transformation |
|-----------------|-----------------|-------------------|----------------|
| `user.id` | `Employee` | `ExternalAdId` | Direct |
| `user.displayName` | `Employee` | `FullName.DisplayName` | Parse into FirstName + LastName |
| `user.givenName` | `Employee` | `FullName.FirstName` | Direct |
| `user.surname` | `Employee` | `FullName.LastName` | Direct |
| `user.mail` | `Employee` | `Email.Value` | Lowercase |
| `user.department` | `Department` | `Name` | Upsert by name |
| `user.manager.id` | `Employee` | `ManagerId` | Resolve to internal EmployeeId |
| `user.accountEnabled` | `Employee` | `IsActive` | Direct boolean |
| `user.jobTitle` | _(role hint)_ | `EmployeeRole` | See role assignment below |

**Role assignment logic (BR-058)**

```
IF employee.id ∈ AD Group "VacationSystem-DepartmentManagers" → Role = DepartmentManager
IF employee.id ∈ AD Group "VacationSystem-ProjectManagers"   → Role = ProjectManager
IF employee.id ∈ AD Group "VacationSystem-Admins"            → Role = Administrator
ELSE                                                           → Role = Employee (default)
```

> Note: Role assignment via AD group is the primary mechanism. Manual override is possible
> via the admin panel (F-007, US-028) and is preserved across subsequent syncs.

---

## Sync Algorithm

:::mermaid
flowchart TD
    A([SyncJob Started]) --> B[Fetch all users from Graph API\nwith paging 100 users/page]
    B --> C{For each AD user}
    C --> D{Employee exists\nin system?}
    D -->|No| E[Create Employee\nStatus = Active\nRole = Employee default]
    D -->|Yes| F{AD accountEnabled?}
    F -->|true| G[Update fields:\nname, email, dept, manager]
    F -->|false| H[Soft-delete:\nIsActive = false\nBR-056]
    E --> I[Resolve Department\nupsert by name]
    G --> I
    H --> J
    I --> J{Error?}
    J -->|Yes| K[Record SyncError\nRetry up to 3x\nExp backoff]
    J -->|No| L[Increment counters]
    K --> L
    L --> C
    C -->|Done| M[Complete SyncJob\nWrite summary log\nAC-012.6]
    M --> N([Publish SyncJobCompleted event])
:::

---

## Domain Events

```csharp
// Published at the end of each sync job (success or failure)
public record SyncJobCompleted(
    Guid EventId, DateTime OccurredOn,
    SyncJobId JobId,
    SyncJobType JobType,
    SyncJobStatus Status,
    int TotalProcessed,
    int Created,
    int Updated,
    int Deactivated,
    int ErrorCount
) : IDomainEvent;

// Published when a new employee is created during sync
public record EmployeeCreatedFromAD(
    Guid EventId, DateTime OccurredOn,
    EmployeeId EmployeeId,
    string ExternalAdId,
    string FullName,
    string Email
) : IDomainEvent;

// Published when an employee is deactivated during sync
public record EmployeeDeactivatedFromAD(
    Guid EventId, DateTime OccurredOn,
    EmployeeId EmployeeId,
    string ExternalAdId
) : IDomainEvent;
```

---

## Database Schema (Azure SQL)

:::mermaid
erDiagram
    SYNC_JOBS {
        uniqueidentifier Id PK
        tinyint Type
        tinyint Status
        datetime2 StartedAt
        datetime2 CompletedAt
        int TotalProcessed
        int Created
        int Updated
        int Deactivated
        int ErrorCount
        nvarchar_256 TriggeredBy
    }

    SYNC_ERRORS {
        uniqueidentifier Id PK
        uniqueidentifier JobId FK
        nvarchar_256 EmployeeExternalId
        nvarchar_2000 ErrorMessage
        int RetryCount
        bit IsResolved
        datetime2 CreatedAt
    }

    SYNC_JOBS ||--o{ SYNC_ERRORS : "records failures"
:::

**Key modifications to existing entities**

The sync job updates the `EMPLOYEES` table (defined in F-001 data model) with additional fields:

| Table | Column Added | Type | Purpose |
|-------|-------------|------|---------|
| `EMPLOYEES` | `ExternalAdId` | `nvarchar(256)` | AD Object ID for sync upsert lookups |
| `EMPLOYEES` | `LastSyncedAt` | `datetime2` | When this employee was last updated by AD sync |
| `DEPARTMENTS` | `ExternalAdId` | `nvarchar(256)` | AD department attribute value |
| `DEPARTMENTS` | `LastSyncedAt` | `datetime2` | When this department was last synced |

**Index strategy**

| Table | Index | Columns | Purpose |
|-------|-------|---------|---------|
| `SYNC_JOBS` | `IX_SJ_Status_StartedAt` | `Status`, `StartedAt` | Prevent duplicate running jobs; history query |
| `SYNC_JOBS` | `IX_SJ_StartedAt_Retention` | `StartedAt` | 90-day retention cleanup (BR-068) |
| `SYNC_ERRORS` | `IX_SE_JobId_Resolved` | `JobId`, `IsResolved` | Fetch unresolved errors per job |
| `EMPLOYEES` | `IX_EMP_ExternalAdId` | `ExternalAdId` | Fast upsert during sync (unique lookup) |

---

## CQRS Commands and Queries

### Commands (F-004)

```csharp
// Triggered by the BackgroundService cron (2:00 AM)
public record TriggerScheduledAdSyncCommand() : ICommand<SyncJobId>;

// Triggered by admin clicking "Sync Now" (US-014) — AC-014.3: prevents duplicate
public record TriggerManualAdSyncCommand(EmployeeId TriggeredBy) : ICommand<SyncJobId>;

// Internal command — processed per-employee inside the sync job
public record UpsertEmployeeFromAdCommand(
    string ExternalAdId,
    string FirstName,
    string LastName,
    string Email,
    string Department,
    string? ManagerExternalAdId,
    bool AccountEnabled,
    SyncJobId SyncJobId
) : ICommand;
```

### Queries (F-004)

```csharp
// Admin panel: last sync status — AC-015.1
public record GetLastSyncJobStatusQuery() : IQuery<SyncJobStatusDto>;

// Admin panel: sync history last 30 days — AC-015.3
public record GetSyncJobHistoryQuery(
    int Days = 30,
    int Page = 1,
    int PageSize = 20
) : IQuery<PagedResult<SyncJobSummaryDto>>;

// Admin panel: errors for a specific job — AC-015.4
public record GetSyncJobErrorsQuery(
    SyncJobId JobId
) : IQuery<IReadOnlyList<SyncErrorDto>>;
```

---

## Non-Functional Constraints

| Constraint | Target | Implementation |
|------------|--------|----------------|
| Job duration | < 30 min for 500 employees (NFR-003) | Parallel batch processing, 100 users per page |
| Retry logic | Max 3 attempts per record, exponential backoff: 1s → 5s → 30s | Polly retry policy |
| Job locking | Only 1 running job at any time | `IDistributedLock` via Redis |
| Rate limiting | Max 1 manual sync per hour | Timestamp check before creating manual job |
| AD access | Read-only via Managed Identity (no credentials in code) | Microsoft.Graph SDK + DefaultAzureCredential |
| Error threshold | Alert admin if error rate > 5% (BR-069) | Metric evaluated at job completion |

---

## Ubiquitous Language

| Term | Definition | Context |
|------|------------|---------|
| **AD Sync** | The nightly process that reads Active Directory data and updates the system's employee records | IdentitySync |
| **Sync Job** | A single execution of the AD synchronization process (scheduled or manual) | IdentitySync |
| **Soft Delete** | Setting `IsActive = false` on an employee who no longer exists in AD; record is preserved | IdentitySync |
| **Upsert** | Insert the record if it doesn't exist; update it if it does (key: `ExternalAdId`) | IdentitySync |
| **External AD ID** | The unique Object ID assigned to a user in Azure Active Directory | IdentitySync |
| **Manual Sync** | An on-demand AD sync triggered by an administrator (US-014) | IdentitySync |
| **Sync Error** | A single employee record that failed to process during a sync job | IdentitySync |
| **Role Assignment** | The process of mapping AD group membership to the system's `EmployeeRole` | IdentitySync |

---

## Integration with Other Bounded Contexts

| Bounded Context | Direction | Mechanism | Data |
|-----------------|-----------|-----------|------|
| **Azure AD / Graph API** | Inbound | Microsoft.Graph SDK (HTTP REST) | User, department, manager data |
| **Organization BC** | Outbound (write) | CQRS commands | Upsert Employee, Department entities |
| **Notifications (F-006)** | Outbound (events) | Service Bus | `SyncJobCompleted` → alert admin if error rate > 5% |
| **Azure Monitor** | Outbound | OTel metrics | Sync duration, error rate, processed count |
