# Domain Model — F-005: ServiceNow Integration

## Metadata

| Property        | Value                                                 |
| --------------- | ----------------------------------------------------- |
| Feature         | F-005 — ServiceNow Integration                        |
| Bounded Context | ServiceNowIntegration (Supporting Domain)             |
| Source          | UC-016 · UC-017 · UC-018 · US-016–018                |
| Created         | 2026-08-07                                            |
| Author          | Bolt DDD Agent                                        |
| Status          | Draft                                                 |

---

## Bounded Context Overview

:::mermaid
flowchart TB
    subgraph SNI["🟤 ServiceNowIntegration (Supporting Domain)"]
        EJ["ExportJob\n(Aggregate Root)"]
        ER["ExportRecord\n(Child Entity)"]
        IJ["ImportJob\n(Aggregate Root)"]
        EJ -->|owns| ER
    end

    subgraph VM["🟠 VacationManagement (Core - F-001)"]
        VR["VacationRequest\n(read + update IsExported)"]
    end

    subgraph ORG["🔵 Organization (Supporting - F-004)"]
        EMP["Employee\n(VacationBalance updated by import)"]
    end

    subgraph SN["☁️ ServiceNow (External ITSM)"]
        TABLE["Table API\n(REST)"]
    end

    subgraph KV["🔑 Azure Key Vault"]
        CREDS["ServiceNow API credentials"]
    end

    subgraph MON["📊 Azure Monitor"]
        OTel["OTel Metrics"]
    end

    TABLE -->|"Approved vacations\nexport 4:00 AM"| EJ
    TABLE -->|"Balance import\n6:00 AM"| IJ
    EJ -->|marks IsExported| VR
    IJ -->|updates VacationBalance| EMP
    KV --> SNI
    SNI --> MON

    style SNI fill:#efebe9,stroke:#4e342e,stroke-width:2px
    style VM fill:#fff3e0,stroke:#e65100,stroke-width:1px
    style ORG fill:#e3f2fd,stroke:#1565c0,stroke-width:1px
    style SN fill:#f1f8e9,stroke:#558b2f,stroke-width:1px
    style KV fill:#fce4ec,stroke:#880e4f,stroke-width:1px
:::

---

## Aggregate Model

:::mermaid
classDiagram
    class ExportJob {
        +ExportJobId Id
        +ExportJobStatus Status
        +DateTime StartedAt
        +DateTime? CompletedAt
        +int TotalExported
        +int TotalUpdated
        +int TotalDeleted
        +int ErrorCount
        +IReadOnlyList~ExportRecord~ Records
        +AddRecord(requestId, serviceNowId?, action)
        +RecordSuccess(exportRecordId, serviceNowId)
        +RecordFailure(exportRecordId, errorMessage)
        +Complete()
        +Fail(reason)
    }

    class ExportRecord {
        +ExportRecordId Id
        +ExportJobId JobId
        +VacationRequestId RequestId
        +ExportAction Action
        +ExportRecordStatus Status
        +string? ServiceNowRecordId
        +DateTime? ExportedAt
        +string? ErrorMessage
        +int RetryCount
        +Retry() bool
    }

    class ImportJob {
        +ImportJobId Id
        +ImportJobStatus Status
        +DateTime StartedAt
        +DateTime? CompletedAt
        +int TotalProcessed
        +int Updated
        +int ErrorCount
    }

    class ExportAction {
        <<Enumeration>>
        Create
        Update
        Delete
    }

    class ExportJobStatus {
        <<Enumeration>>
        Running
        Completed
        CompletedWithErrors
        Failed
    }

    class ExportRecordStatus {
        <<Enumeration>>
        Pending
        Succeeded
        Failed
        MaxRetriesExceeded
    }

    class ImportJobStatus {
        <<Enumeration>>
        Running
        Completed
        CompletedWithErrors
        Failed
    }

    ExportJob "1" *-- "0..*" ExportRecord : owns
    ExportRecord --> ExportAction : action
    ExportRecord --> ExportRecordStatus : status
:::

---

## Entity Definitions

### ExportJob _(Aggregate Root)_

Records the execution of the nightly vacation export batch to ServiceNow. Manages all
individual record-level results. Runs at 4:00 AM (BR-074), after AD sync completes.

| Property | Type | Constraints |
|----------|------|-------------|
| `Id` | `ExportJobId` | Required, unique, GUID-based |
| `Status` | `ExportJobStatus` | `Running → Completed / CompletedWithErrors / Failed` |
| `StartedAt` | `DateTime` (UTC) | Set on job start; immutable |
| `CompletedAt` | `DateTime?` (UTC) | Set on completion |
| `TotalExported` | `int` | Records successfully POSTed to ServiceNow |
| `TotalUpdated` | `int` | Records sent as updates (previously exported, status changed) |
| `TotalDeleted` | `int` | Cancelled requests removed from ServiceNow |
| `ErrorCount` | `int` | Records that failed all retries |
| `Records` | `IReadOnlyList<ExportRecord>` | One child per VacationRequest processed in this batch |

**Invariants**

| # | Invariant | Source |
|---|-----------|--------|
| INV-401 | Only Approved requests (both levels) may be exported (BR-071) | BR-071 |
| INV-402 | Delta sync: only records changed since last successful export (BR-072) | BR-072 |
| INV-403 | A failed record does not block other records in the batch (BR-075) | BR-075 |
| INV-404 | Only one `Running` export job at any time | Domain rule |

---

### ExportRecord _(Child Entity of ExportJob)_

Tracks the ServiceNow export status of a single `VacationRequest`. Supports up to 3 retry
attempts with exponential backoff (1s → 5s → 30s) before entering `MaxRetriesExceeded`.

| Property | Type | Constraints |
|----------|------|-------------|
| `Id` | `ExportRecordId` | Required, unique, GUID-based |
| `JobId` | `ExportJobId` | Required, FK to parent `ExportJob` |
| `RequestId` | `VacationRequestId` | Required; the vacation request being exported |
| `Action` | `ExportAction` | `Create`, `Update`, or `Delete` |
| `Status` | `ExportRecordStatus` | `Pending → Succeeded / Failed → MaxRetriesExceeded` |
| `ServiceNowRecordId` | `string?` | ServiceNow `sys_id` returned on successful Create/Update |
| `ExportedAt` | `DateTime?` (UTC) | Set on success |
| `ErrorMessage` | `string?` | Last error message for failed attempts |
| `RetryCount` | `int` | 0–3; `Retry()` returns `false` when 3 is reached |

---

### ImportJob _(Aggregate Root)_

Records the nightly import of employee vacation balance data from ServiceNow.
Runs at 6:00 AM (BR-076), updates `Employee.VacationBalance` for all active employees.

| Property | Type | Constraints |
|----------|------|-------------|
| `Id` | `ImportJobId` | Required, unique, GUID-based |
| `Status` | `ImportJobStatus` | `Running → Completed / CompletedWithErrors / Failed` |
| `StartedAt` | `DateTime` (UTC) | Set on job start; immutable |
| `CompletedAt` | `DateTime?` (UTC) | Set on completion |
| `TotalProcessed` | `int` | Total employee balance records fetched |
| `Updated` | `int` | Employees whose balance was updated |
| `ErrorCount` | `int` | Records that failed |

---

## ServiceNow Field Mapping

The following table is the **authoritative field mapping** between the internal vacation request
model and the ServiceNow table. (Q-013: exact table name and fields to be confirmed with
ServiceNow team before Bolt 5.)

| Internal Field | ServiceNow Field | Direction | Notes |
|----------------|-----------------|-----------|-------|
| `VacationRequest.Id` | `u_vacation_sys_id` | Export → SN | Internal GUID as external reference |
| `Employee.FullName` | `u_employee_name` | Export → SN | Denormalized full name |
| `Employee.ExternalAdId` | `u_employee_ad_id` | Export → SN | AD Object ID for SN cross-reference |
| `DateRange.StartDate` | `u_start_date` | Export → SN | ISO 8601 date |
| `DateRange.EndDate` | `u_end_date` | Export → SN | ISO 8601 date |
| `DateRange.TotalBusinessDays` | `u_total_days` | Export → SN | Integer |
| `VacationRequest.Status` | `u_status` | Export → SN | `"approved"` only exported |
| `Department.Name` | `u_department` | Export → SN | Display name |
| `VacationBalance.TotalDays` | `u_vacation_total` | SN → Import | Annual entitlement |
| `VacationBalance.UsedDays` | `u_vacation_used` | SN → Import | Days already taken |
| `VacationBalance.PendingDays` | `u_vacation_pending` | SN → Import | Days pending approval |

---

## Export Algorithm

:::mermaid
flowchart TD
    A([ExportJob Started — 4:00 AM]) --> B[Query: Approved requests\nnot yet exported\nOR changed since last export\nBR-072 delta]
    B --> C[Query: Cancelled requests\nwith ServiceNowRecordId set\nBR-073]
    B --> D{For each Approved request}
    C --> E{For each Cancelled request}

    D --> F{Has ServiceNowRecordId?}
    F -->|No| G[POST to SN Table API\nCreate new record]
    F -->|Yes| H[PATCH to SN Table API\nUpdate existing record]

    E --> I[DELETE / update to SN\nRemove record]

    G --> J{Success?}
    H --> J
    I --> J

    J -->|Yes| K[Mark IsExported = true\nStore ServiceNowId\nAC-016.3]
    J -->|No, RetryCount < 3| L[Retry with exp. backoff\n1s → 5s → 30s]
    J -->|No, RetryCount = 3| M[Mark MaxRetriesExceeded\nAC-016.5]

    K --> N[Increment counters]
    L --> D
    M --> N
    N --> D
    D --> O[Complete ExportJob\nWrite summary log AC-016.6]
    O --> P([Publish ExportJobCompleted event])
:::

---

## Domain Events

```csharp
// Published at end of each export batch
public record ExportJobCompleted(
    Guid EventId, DateTime OccurredOn,
    ExportJobId JobId,
    ExportJobStatus Status,
    int TotalExported,
    int TotalUpdated,
    int TotalDeleted,
    int ErrorCount
) : IDomainEvent;

// Published when an export record fails all 3 retries (triggers admin alert)
public record ExportRecordPermanentlyFailed(
    Guid EventId, DateTime OccurredOn,
    ExportRecordId RecordId,
    VacationRequestId RequestId,
    string LastErrorMessage
) : IDomainEvent;

// Published at end of each balance import batch
public record ImportJobCompleted(
    Guid EventId, DateTime OccurredOn,
    ImportJobId JobId,
    ImportJobStatus Status,
    int Updated,
    int ErrorCount
) : IDomainEvent;
```

---

## Modifications to Existing Entities

F-005 adds the following fields to entities defined in earlier features:

**VacationRequest** (F-001) — adds export tracking:

| Column Added | Type | Purpose |
|-------------|------|---------|
| `IsExported` | `bit` (bool) | Whether this request has been successfully exported |
| `ExportedAt` | `datetime2?` | When it was first exported to ServiceNow |
| `ServiceNowRecordId` | `nvarchar(128)?` | ServiceNow `sys_id` for updates/deletes |
| `LastExportedAt` | `datetime2?` | When it was last exported (for delta sync) |

**Employee** (F-001/F-004) — adds balance from import:

| Column Added | Type | Purpose |
|-------------|------|---------|
| `VacationTotalDays` | `int` | Annual entitlement from ServiceNow |
| `VacationUsedDays` | `int` | Days already taken |
| `BalanceUpdatedAt` | `datetime2?` | Last balance import timestamp (BR-079) |

---

## Database Schema (Azure SQL)

:::mermaid
erDiagram
    EXPORT_JOBS {
        uniqueidentifier Id PK
        tinyint Status
        datetime2 StartedAt
        datetime2 CompletedAt
        int TotalExported
        int TotalUpdated
        int TotalDeleted
        int ErrorCount
    }

    EXPORT_RECORDS {
        uniqueidentifier Id PK
        uniqueidentifier JobId FK
        uniqueidentifier RequestId FK
        tinyint Action
        tinyint Status
        nvarchar_128 ServiceNowRecordId
        datetime2 ExportedAt
        nvarchar_2000 ErrorMessage
        int RetryCount
    }

    IMPORT_JOBS {
        uniqueidentifier Id PK
        tinyint Status
        datetime2 StartedAt
        datetime2 CompletedAt
        int TotalProcessed
        int Updated
        int ErrorCount
    }

    EXPORT_JOBS ||--o{ EXPORT_RECORDS : "tracks"
:::

**Index strategy**

| Table | Index | Columns | Purpose |
|-------|-------|---------|---------|
| `EXPORT_RECORDS` | `IX_ER_RequestId` | `RequestId` | Check if request was previously exported |
| `EXPORT_RECORDS` | `IX_ER_Status_RetryCount` | `Status`, `RetryCount` | Admin retry query (US-018) |
| `EXPORT_JOBS` | `IX_EJ_Status_StartedAt` | `Status`, `StartedAt` | Prevent duplicate running jobs; history |
| `VACATION_REQUESTS` | `IX_VR_IsExported_Status` | `IsExported`, `Status` | Delta sync query (BR-072) |

---

## CQRS Commands and Queries

### Commands (F-005)

```csharp
// Triggered by BackgroundService cron (4:00 AM)
public record TriggerNightlyExportCommand() : ICommand<ExportJobId>;

// Triggered by BackgroundService cron (6:00 AM)
public record TriggerNightlyBalanceImportCommand() : ICommand<ImportJobId>;

// Admin manual retry of a specific failed record (US-018, AC-018.3)
public record RetryExportRecordCommand(
    ExportRecordId RecordId,
    EmployeeId TriggeredBy
) : ICommand;
```

### Queries (F-005)

```csharp
// Admin panel: last export status — AC-018.1
public record GetLastExportJobStatusQuery() : IQuery<ExportJobStatusDto>;

// Admin panel: failed records for a job — AC-018.2
public record GetFailedExportRecordsQuery(
    ExportJobId? JobId = null   // null = latest job
) : IQuery<IReadOnlyList<FailedExportRecordDto>>;

// Admin panel: 30-day export history — AC-018.5
public record GetExportJobHistoryQuery(
    int Days = 30
) : IQuery<IReadOnlyList<ExportJobSummaryDto>>;
```

---

## Non-Functional Constraints

| Constraint | Target | Implementation |
|------------|--------|----------------|
| Batch duration | < 15 min for 50 records (NFR-004) | Sequential with async HTTP; circuit breaker |
| Per-record latency | < 2 s per ServiceNow API call | Polly timeout policy |
| Retry | Max 3 attempts, backoff: 1s → 5s → 30s | Polly retry with exponential jitter |
| Circuit breaker | If ServiceNow down → skip job, alert admin (BR-078) | Polly circuit breaker (5 failures = open) |
| Delta sync | Only export changed records since last successful run | Track `LastExportedAt` per record |
| Credentials | ServiceNow API key/OAuth stored in Key Vault | Managed Identity + Key Vault reference |
| Error alert | Notify admin if > 5% error rate (BR-081) | Evaluated in `ExportJobCompleted` handler |

---

## Ubiquitous Language

| Term | Definition | Context |
|------|------------|---------|
| **Export Job** | A single execution of the nightly batch that sends approved vacations to ServiceNow | ServiceNowIntegration |
| **Export Record** | The status of a single vacation request within an export batch | ServiceNowIntegration |
| **Import Job** | A single execution of the nightly batch that imports vacation balances from ServiceNow | ServiceNowIntegration |
| **Delta Sync** | Exporting only records that are new or changed since the last successful export | ServiceNowIntegration |
| **ServiceNow Record ID** | The `sys_id` returned by ServiceNow on a successful create; used for updates and deletes | ServiceNowIntegration |
| **Vacation Balance** | Employee entitlement data (total, used, remaining days) imported from ServiceNow | ServiceNowIntegration |
| **Stale Balance** | Vacation balance data from a previous import, used when ServiceNow is unavailable (BR-078) | ServiceNowIntegration |
| **Permanent Failure** | An export record that failed all 3 retry attempts; requires admin manual retry | ServiceNowIntegration |
| **Circuit Breaker** | Pattern that stops calling ServiceNow when it is consistently unavailable | ServiceNowIntegration |

---

## Integration with Other Bounded Contexts

| Bounded Context | Direction | Mechanism | Data |
|-----------------|-----------|-----------|------|
| **ServiceNow Table API** | Outbound | HTTP REST (Polly) | POST/PATCH/DELETE vacation records; GET balance data |
| **VacationManagement (F-001)** | Outbound (write) | CQRS command | Update `IsExported`, `ServiceNowRecordId` on VacationRequest |
| **Organization (F-004)** | Outbound (write) | CQRS command | Update `VacationBalance` on Employee |
| **Notifications (F-006)** | Outbound (events) | Service Bus | `ExportRecordPermanentlyFailed` → alert admin |
| **Azure Key Vault** | Inbound | Managed Identity | ServiceNow API credentials (never in config files) |
| **Azure Monitor** | Outbound | OTel metrics | Export duration, error rate, records processed |
