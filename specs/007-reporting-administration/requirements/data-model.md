# Domain Model — F-007: Reporting & Administration

## Metadata

| Property        | Value                                               |
| --------------- | --------------------------------------------------- |
| Feature         | F-007 — Reporting & Administration                  |
| Bounded Context | ReportingAdmin (Supporting Domain)                  |
| Source          | UC-023 · UC-024 · UC-025 · UC-026 · UC-027 · UC-028 · US-023–028 |
| Created         | 2026-08-07                                          |
| Author          | Bolt DDD Agent                                      |
| Status          | Draft                                               |

---

## Bounded Context Overview

:::mermaid
flowchart TB
    subgraph RA["🟡 ReportingAdmin (Supporting Domain)"]
        AE["AuditEntry\n(Aggregate Root — immutable)"]
        SC["SystemConfiguration\n(Aggregate Root)"]
        RE["ReportExecution\n(Aggregate Root)"]
    end

    subgraph SOURCES["📊 Read Sources (Dapper queries)"]
        VR["VacationRequest"]
        AS["ApprovalStep"]
        EMP["Employee"]
        DEPT["Department"]
        CS["CapacitySnapshot"]
    end

    subgraph EF["🔷 EF Core Interceptor"]
        INT["AuditInterceptor\n(SaveChangesInterceptor)"]
    end

    subgraph BLOB["📁 Azure Blob Storage"]
        RPT["Exported report files\n(.csv / .xlsx / .pdf)"]
    end

    INT -->|captures every change| AE
    SOURCES -->|Dapper read models| RE
    RE -->|stores result| BLOB

    style RA fill:#fff8e1,stroke:#f57f17,stroke-width:2px
    style SOURCES fill:#e3f2fd,stroke:#1565c0,stroke-width:1px
    style EF fill:#f3e5f5,stroke:#6a1b9a,stroke-width:1px
    style BLOB fill:#e8f5e9,stroke:#2e7d32,stroke-width:1px
:::

---

## Aggregate Model

:::mermaid
classDiagram
    class AuditEntry {
        +AuditEntryId Id
        +DateTime Timestamp
        +EmployeeId? UserId
        +string UserDisplayName
        +AuditActionType ActionType
        +string EntityType
        +string EntityId
        +string? OldValuesJson
        +string? NewValuesJson
        +string? AdditionalContext
        +AuditSource Source
    }

    class SystemConfiguration {
        +SystemConfigurationId Id
        +string Key
        +string Value
        +ConfigScope Scope
        +Guid? DepartmentId
        +DateTime UpdatedAt
        +EmployeeId UpdatedBy
        +string? PreviousValue
        +T GetValue~T~() T
        +Update(newValue, updatedBy)
    }

    class ReportExecution {
        +ReportExecutionId Id
        +ReportType ReportType
        +string ParametersJson
        +EmployeeId GeneratedBy
        +DateTime RequestedAt
        +DateTime? CompletedAt
        +ReportExecutionStatus Status
        +string? FileUrl
        +ReportFormat Format
        +long? FileSizeBytes
    }

    class AuditActionType {
        <<Enumeration>>
        Created
        Updated
        Deleted
        StatusChanged
        Approved
        Rejected
        Cancelled
        Delegated
        Escalated
        Exported
        Imported
        ConfigChanged
        RoleChanged
        LoginSuccess
        LoginFailed
    }

    class AuditSource {
        <<Enumeration>>
        UserAction
        System
        BackgroundJob
        Integration
    }

    class ConfigScope {
        <<Enumeration>>
        Global
        Department
    }

    class ReportType {
        <<Enumeration>>
        VacationHistory
        ApprovalTime
        Coverage
        AuditLog
    }

    class ReportFormat {
        <<Enumeration>>
        Csv
        Excel
        Pdf
    }

    class ReportExecutionStatus {
        <<Enumeration>>
        Queued
        Generating
        Completed
        Failed
    }
:::

---

## Entity Definitions

### AuditEntry _(Aggregate Root — immutable)_

The foundational compliance record for the system. Captures every state-changing operation
with full before/after values. Append-only (INV-601); no updates or deletes allowed.
Retained for 7 years (BR-117). Total projected volume: ~840,000 entries over 7 years.

| Property | Type | Constraints |
|----------|------|-------------|
| `Id` | `AuditEntryId` | Required, unique, GUID-based |
| `Timestamp` | `DateTime` (UTC) | Required; set by interceptor, not caller (BR-120) |
| `UserId` | `EmployeeId?` | `null` for system/background jobs |
| `UserDisplayName` | `string` | Denormalized snapshot of user name at time of action |
| `ActionType` | `AuditActionType` | Required; categorizes the operation |
| `EntityType` | `string` | e.g., `"VacationRequest"`, `"Employee"`, `"Delegation"` |
| `EntityId` | `string` | String representation of the entity's primary key |
| `OldValuesJson` | `string?` | JSON of entity state before change; `null` for Create actions |
| `NewValuesJson` | `string?` | JSON of entity state after change; `null` for Delete actions |
| `AdditionalContext` | `string?` | Optional free text (e.g., rejection reason summary) |
| `Source` | `AuditSource` | `UserAction`, `System`, `BackgroundJob`, or `Integration` |

**Invariants**

| # | Invariant | Source |
|---|-----------|--------|
| INV-601 | `AuditEntry` is strictly append-only; no UPDATE or DELETE on `AUDIT_ENTRIES` table | BR-116 |
| INV-602 | `Timestamp` is always UTC; set by the EF Core interceptor (not the application clock) | BR-120 |
| INV-603 | Both `OldValuesJson` and `NewValuesJson` must respect PII redaction rules | GDPR |
| INV-604 | Minimum retention period: 7 years (must survive DB migrations) | BR-117 |

**EF Core Interceptor implementation note**

```csharp
// AuditInterceptor is registered as a SaveChangesInterceptor
// It captures EntityEntry<> states before and after Save and writes AuditEntry records
// to the same UoW transaction — ensuring consistency and no silent failures.
public class AuditInterceptor : SaveChangesInterceptor
{
    public override async ValueTask<InterceptionResult<int>> SavingChangesAsync(
        DbContextEventData eventData, InterceptionResult<int> result, CancellationToken ct)
    {
        // Capture changed entities, produce AuditEntry records, append to context
        ...
    }
}
```

---

### SystemConfiguration _(Aggregate Root)_

Key-value store for all configurable system parameters. Supports global defaults and
per-department overrides (BR-124). Changes take effect immediately with no restart (BR-122).
Every change is audited automatically via the `AuditInterceptor`.

| Property | Type | Constraints |
|----------|------|-------------|
| `Id` | `SystemConfigurationId` | Required, unique, GUID-based |
| `Key` | `string` | Required; defines the setting (see table below) |
| `Value` | `string` | Required; all values stored as strings; deserialized by `GetValue<T>()` |
| `Scope` | `ConfigScope` | `Global` or `Department` |
| `DepartmentId` | `Guid?` | Required when `Scope = Department`; `null` for global |
| `UpdatedAt` | `DateTime` (UTC) | Audit |
| `UpdatedBy` | `EmployeeId` | Must have `Administrator` role |
| `PreviousValue` | `string?` | Previous value stored on every update for audit (AC-027.5) |

**Configuration key catalogue**

| Key | Type | Default | Scope | Feature |
|-----|------|---------|-------|---------|
| `capacity.warning_threshold_pct` | `int` | `65` | Global / Department | F-003 |
| `capacity.critical_threshold_pct` | `int` | `70` | Global / Department | F-003 |
| `escalation.reminder_after_days` | `int` | `3` | Global / Department | F-002 |
| `escalation.escalation_after_days` | `int` | `5` | Global / Department | F-002 |
| `adsync.schedule_cron` | `string` | `"0 2 * * *"` | Global | F-004 |
| `export.schedule_cron` | `string` | `"0 4 * * *"` | Global | F-005 |
| `import.schedule_cron` | `string` | `"0 6 * * *"` | Global | F-005 |

**Invariants**

| # | Invariant | Source |
|---|-----------|--------|
| INV-610 | Threshold values must be in range 1–100 (BR-125) | BR-125 |
| INV-611 | `critical_threshold_pct > warning_threshold_pct` | Domain rule |
| INV-612 | Only one configuration record per `(Key, Scope, DepartmentId)` | Domain rule |
| INV-613 | Department scope overrides global for the same key (BR-124) | BR-124 |
| INV-614 | Configuration changes take effect immediately; no caching layer for config | BR-122 |

---

### ReportExecution _(Aggregate Root)_

Tracks the generation of a report, including its parameters, status, and file location.
Report files are stored in Azure Blob Storage and linked via `FileUrl`. Async generation
is queued for large datasets to avoid blocking the API.

| Property | Type | Constraints |
|----------|------|-------------|
| `Id` | `ReportExecutionId` | Required, unique, GUID-based |
| `ReportType` | `ReportType` | Required |
| `ParametersJson` | `string` | JSON-serialized filters (date range, department, etc.) |
| `GeneratedBy` | `EmployeeId` | Required |
| `RequestedAt` | `DateTime` (UTC) | When the report was requested |
| `CompletedAt` | `DateTime?` (UTC) | When generation finished |
| `Status` | `ReportExecutionStatus` | `Queued → Generating → Completed / Failed` |
| `FileUrl` | `string?` | Azure Blob Storage SAS URL (set on completion) |
| `Format` | `ReportFormat` | `Csv`, `Excel`, or `Pdf` |
| `FileSizeBytes` | `long?` | Size of generated file |

---

## Audit Log Architecture

:::mermaid
flowchart LR
    subgraph APP["Application Layer"]
        CMD["Command Handler\n(EF Core write)"]
        JOB["Background Job\n(sync, export)"]
        API["Admin API\n(config change)"]
    end

    subgraph EF["EF Core / Interceptor"]
        INT["AuditInterceptor\n(SaveChangesInterceptor)"]
    end

    subgraph DB["Azure SQL"]
        AE["AUDIT_ENTRIES\n(append-only)"]
        HOT["HOT partition\n(< 90 days)"]
        WARM["WARM archive\n(90 days – 3 years)"]
        COLD["COLD archive\n(3–7 years, compressed)"]
        AE --> HOT
        HOT -.->|automated move| WARM
        WARM -.->|automated move| COLD
    end

    CMD --> INT
    JOB --> INT
    API --> INT
    INT -->|same transaction| AE
:::

**Retention tiers (7-year compliance)**

| Tier | Age | Location | Query Performance |
|------|-----|----------|-------------------|
| Hot | 0–90 days | Azure SQL (indexed) | < 2 seconds |
| Warm | 90 days – 3 years | Azure SQL (partitioned, compressed) | < 10 seconds |
| Cold | 3–7 years | Azure Blob Storage (GZIP) or SQL archive | Export only |

---

## Report Read Models (Dapper)

Reports are read-only queries against denormalized Dapper read models. They do NOT use EF Core
to avoid N+1 issues and to achieve the 5-second NFR target.

### VacationHistoryReportRow

```csharp
public record VacationHistoryReportRow(
    string EmployeeName,
    string DepartmentName,
    string ProjectName,
    DateOnly StartDate,
    DateOnly EndDate,
    int TotalDays,
    string Status,
    DateTime SubmittedAt,
    string? ProjectApproverName,
    DateTime? ProjectApprovedAt,
    string? DepartmentApproverName,
    DateTime? DepartmentApprovedAt
);
```

### ApprovalTimeReportRow

```csharp
public record ApprovalTimeReportRow(
    string ApproverName,
    string DepartmentName,
    int TotalApprovals,
    double AverageBusinessDays,
    double MedianBusinessDays,
    int MinDays,
    int MaxDays,
    int EscalatedCount
);
```

### CoverageReportRow

```csharp
public record CoverageReportRow(
    DateOnly Date,                   // or week-start date
    string DepartmentName,
    int TotalEmployees,
    int EmployeesOnVacation,
    decimal CoveragePercent,
    bool ExceedsThreshold
);
```

---

## Database Schema (Azure SQL)

:::mermaid
erDiagram
    AUDIT_ENTRIES {
        uniqueidentifier Id PK
        datetime2 Timestamp
        uniqueidentifier UserId
        nvarchar_200 UserDisplayName
        tinyint ActionType
        nvarchar_100 EntityType
        nvarchar_100 EntityId
        nvarchar_max OldValuesJson
        nvarchar_max NewValuesJson
        nvarchar_500 AdditionalContext
        tinyint Source
    }

    SYSTEM_CONFIGURATIONS {
        uniqueidentifier Id PK
        nvarchar_100 Key
        nvarchar_2000 Value
        tinyint Scope
        uniqueidentifier DepartmentId
        datetime2 UpdatedAt
        uniqueidentifier UpdatedBy FK
        nvarchar_2000 PreviousValue
    }

    REPORT_EXECUTIONS {
        uniqueidentifier Id PK
        tinyint ReportType
        nvarchar_max ParametersJson
        uniqueidentifier GeneratedBy FK
        datetime2 RequestedAt
        datetime2 CompletedAt
        tinyint Status
        nvarchar_2000 FileUrl
        tinyint Format
        bigint FileSizeBytes
    }
:::

**Index strategy**

| Table | Index | Columns | Purpose |
|-------|-------|---------|---------|
| `AUDIT_ENTRIES` | `IX_AE_Timestamp` | `Timestamp DESC` | Default sort — newest first |
| `AUDIT_ENTRIES` | `IX_AE_UserId_Timestamp` | `UserId`, `Timestamp` | Filter by user — US-026 |
| `AUDIT_ENTRIES` | `IX_AE_EntityType_EntityId` | `EntityType`, `EntityId` | Audit trail for a specific entity |
| `AUDIT_ENTRIES` | `IX_AE_ActionType_Timestamp` | `ActionType`, `Timestamp` | Filter by action type |
| `SYSTEM_CONFIGURATIONS` | `UQ_SC_Key_Scope_Dept` | `Key`, `Scope`, `DepartmentId` | One config per key/scope |
| `REPORT_EXECUTIONS` | `IX_RE_GeneratedBy_Requested` | `GeneratedBy`, `RequestedAt` | User's report history |

---

## CQRS Commands and Queries

### Commands (F-007)

```csharp
// US-027 — Admin changes a system configuration value
public record UpdateSystemConfigurationCommand(
    string Key,
    string NewValue,
    ConfigScope Scope,
    Guid? DepartmentId,
    EmployeeId UpdatedBy
) : ICommand<SystemConfigurationId>;

// US-028 — Admin changes an employee's role
public record ChangeEmployeeRoleCommand(
    EmployeeId TargetEmployeeId,
    EmployeeRole NewRole,
    EmployeeId ChangedBy
) : ICommand;

// US-028 — Admin deactivates a user
public record DeactivateEmployeeCommand(
    EmployeeId TargetEmployeeId,
    EmployeeId DeactivatedBy
) : ICommand;

// US-028 — Admin revokes a delegation
public record AdminRevokeDelegationCommand(
    DelegationId DelegationId,
    EmployeeId RevokedBy
) : ICommand;

// US-023–025: Request report generation (async queue)
public record GenerateReportCommand(
    ReportType ReportType,
    ReportFormat Format,
    string ParametersJson,
    EmployeeId RequestedBy
) : ICommand<ReportExecutionId>;
```

### Queries (F-007)

```csharp
// US-023 — Vacation history report data
public record GetVacationHistoryReportQuery(
    EmployeeId RequestingUserId,
    DateOnly? FromDate,
    DateOnly? ToDate,
    Guid? DepartmentId,
    Guid? ProjectId,
    EmployeeId? EmployeeId,
    VacationStatus? Status,
    int Page = 1,
    int PageSize = 100
) : IQuery<PagedResult<VacationHistoryReportRow>>;

// US-024 — Approval time report
public record GetApprovalTimeReportQuery(
    EmployeeId RequestingUserId,
    DateOnly? FromDate,
    DateOnly? ToDate,
    Guid? DepartmentId
) : IQuery<IReadOnlyList<ApprovalTimeReportRow>>;

// US-025 — Coverage report
public record GetCoverageReportQuery(
    EmployeeId RequestingUserId,
    DateOnly FromDate,
    DateOnly ToDate,
    Guid? DepartmentId,
    CapacityGranularity Granularity = CapacityGranularity.Weekly
) : IQuery<IReadOnlyList<CoverageReportRow>>;

// US-026 — Audit trail with search
public record GetAuditTrailQuery(
    EmployeeId? UserId,
    DateOnly? FromDate,
    DateOnly? ToDate,
    AuditActionType? ActionType,
    string? EntityType,
    string? EntityId,
    int Page = 1,
    int PageSize = 50
) : IQuery<PagedResult<AuditEntryDto>>;

// US-027 — Admin panel: all system configurations
public record GetSystemConfigurationsQuery(
    Guid? DepartmentId = null
) : IQuery<IReadOnlyList<SystemConfigurationDto>>;

// US-028 — User management: search employees
public record SearchEmployeesForAdminQuery(
    string? SearchTerm,
    EmployeeRole? Role,
    Guid? DepartmentId,
    int Page = 1,
    int PageSize = 20
) : IQuery<PagedResult<EmployeeAdminDto>>;
```

---

## Ubiquitous Language

| Term | Definition | Context |
|------|------------|---------|
| **Audit Entry** | An immutable record capturing who performed an action, on what entity, when, and what changed | ReportingAdmin |
| **Audit Trail** | The complete, chronological, searchable sequence of all audit entries | ReportingAdmin |
| **7-Year Retention** | Compliance requirement: audit entries must be preserved for 7 years from creation | ReportingAdmin |
| **Append-Only** | Data cannot be modified or deleted; only new entries can be added | ReportingAdmin |
| **System Configuration** | A named key-value setting that controls system behaviour at global or department scope | ReportingAdmin |
| **Global Config** | A configuration setting that applies to all departments unless overridden | ReportingAdmin |
| **Department Override** | A department-specific config value that supersedes the global default | ReportingAdmin |
| **Report Execution** | A tracked instance of a report generation request, with status and file output | ReportingAdmin |
| **Vacation History Report** | A list of vacation requests filterable by employee, date range, and status | ReportingAdmin |
| **Approval Time Report** | Metrics on how long approvals take per approver or department | ReportingAdmin |
| **Coverage Report** | Daily or weekly capacity percentage per department/project over a date range | ReportingAdmin |
| **Before/After Values** | JSON snapshots of an entity's state before and after a change, stored in AuditEntry | ReportingAdmin |

---

## Integration with Other Bounded Contexts

| Bounded Context | Direction | Mechanism | Data |
|-----------------|-----------|-----------|------|
| **All BCs** | Inbound (write) | EF Core `AuditInterceptor` | Every SaveChanges produces AuditEntry records |
| **VacationManagement (F-001)** | Inbound (read) | Dapper queries | Vacation history report |
| **ApprovalWorkflow (F-002)** | Inbound (read) | Dapper queries | Approval time report; delegation management |
| **CapacityManagement (F-003)** | Inbound (read) | Dapper queries | Coverage report reads CapacitySnapshots |
| **Organization (F-004)** | Bidirectional | CQRS (read + write commands) | User/role management; search employees |
| **Notifications (F-006)** | Inbound (read) | Dapper queries | Template management |
| **Azure Blob Storage** | Outbound | Azure SDK | Store exported report files (CSV/Excel/PDF) |
