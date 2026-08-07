# Domain Model — F-003: Calendar & Capacity Visualization

## Metadata

| Property        | Value                                                    |
| --------------- | -------------------------------------------------------- |
| Feature         | F-003 — Calendar & Capacity Visualization                |
| Bounded Context | CapacityManagement (Supporting Domain)                   |
| Source          | UC-008 · UC-009 · UC-010 · UC-011 · US-008–011          |
| Created         | 2026-08-07                                               |
| Author          | Bolt DDD Agent                                           |
| Status          | Draft                                                    |

---

## Bounded Context Overview

:::mermaid
flowchart TB
    subgraph CM["🟢 CapacityManagement (Supporting Domain)"]
        CS["CapacitySnapshot\n(Aggregate Root)"]
        TC["ThresholdConfig\n(Aggregate Root)"]
    end

    subgraph VM["🟠 VacationManagement (Core - F-001)"]
        VR["VacationRequest\n(read projection)"]
    end

    subgraph ORG["🔵 Organization (Supporting - F-004)"]
        EMP["Employee\n(read projection)"]
        DEPT["Department"]
        PROJ["Project"]
    end

    subgraph CACHE["⚡ Redis Cache"]
        RC["CapacitySnapshot\ncached 30 min"]
    end

    subgraph NOTIF["⚪ Notifications (F-006)"]
        EVT["CapacityThresholdCrossed\nevent"]
    end

    VR -->|approved / pending status| CM
    EMP -->|headcount by dept/project| CM
    DEPT -->|threshold config owner| TC
    CS --> RC
    CM -->|publishes| EVT

    style CM fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style VM fill:#fff3e0,stroke:#e65100,stroke-width:1px
    style ORG fill:#e3f2fd,stroke:#1565c0,stroke-width:1px
    style CACHE fill:#fff9c4,stroke:#f57f17,stroke-width:1px
    style NOTIF fill:#f5f5f5,stroke:#616161,stroke-width:1px
:::

---

## Aggregate Model

:::mermaid
classDiagram
    class CapacitySnapshot {
        +CapacitySnapshotId Id
        +DateOnly Date
        +OrganizationLevel Level
        +Guid LevelEntityId
        +int TotalEmployees
        +int EmployeesOnVacation
        +int EmployeesPending
        +decimal CapacityPercentage
        +bool IsCritical
        +bool IsWarning
        +DateTime ComputedAt
        +ComputePercentage() decimal
        +IsCriticalFor(ThresholdConfig) bool
    }

    class ThresholdConfig {
        +ThresholdConfigId Id
        +ThresholdScope Scope
        +Guid? DepartmentId
        +int WarningThresholdPct
        +int CriticalThresholdPct
        +DateTime UpdatedAt
        +EmployeeId UpdatedBy
        +bool IsApplicableTo(Guid departmentId) bool
    }

    class OrganizationLevel {
        <<Enumeration>>
        Department
        Project
        Team
    }

    class ThresholdScope {
        <<Enumeration>>
        Global
        Department
    }

    class CapacityPeriod {
        <<Value Object>>
        +DateOnly StartDate
        +DateOnly EndDate
        +CapacityGranularity Granularity
        +IEnumerable~DateOnly~ GetDates()
    }

    class CapacityGranularity {
        <<Enumeration>>
        Daily
        Weekly
    }

    CapacitySnapshot --> OrganizationLevel : scoped to
    ThresholdConfig --> ThresholdScope : applied at
:::

---

## Entity Definitions

### CapacitySnapshot _(Aggregate Root)_

Pre-computed daily capacity record for a specific organizational level (department, project, or
team). Recomputed on every approval, rejection, or cancellation event via Service Bus. Backed
by Redis (L2 cache, 30 minutes TTL) to serve calendar and heat-map queries under 1 second.

| Property | Type | Constraints |
|----------|------|-------------|
| `Id` | `CapacitySnapshotId` | Required, unique, GUID-based |
| `Date` | `DateOnly` | Required; one record per date per level entity |
| `Level` | `OrganizationLevel` | Required: `Department`, `Project`, or `Team` |
| `LevelEntityId` | `Guid` | Required; FK to Department/Project/Team |
| `TotalEmployees` | `int` | Active employees at this org level on this date |
| `EmployeesOnVacation` | `int` | Approved requests covering this date |
| `EmployeesPending` | `int` | Pending requests covering this date |
| `CapacityPercentage` | `decimal` | `(EmployeesOnVacation + EmployeesPending) / TotalEmployees × 100` |
| `IsCritical` | `bool` | `CapacityPercentage > CriticalThresholdPct` (default > 70%) |
| `IsWarning` | `bool` | `65 ≤ CapacityPercentage ≤ 70` |
| `ComputedAt` | `DateTime` (UTC) | When snapshot was last calculated |

**Invariants**

| # | Invariant | Source |
|---|-----------|--------|
| INV-201 | Unique composite key: `(Date, Level, LevelEntityId)` | Upsert logic |
| INV-202 | `CapacityPercentage` uses both Approved AND Pending (BR-043) | BR-043 |
| INV-203 | Snapshot is invalidated (recalculated) on every status-change event | BR-044 |
| INV-204 | Total employees = headcount from current Employee table (active only) | Domain rule |

---

### ThresholdConfig _(Aggregate Root)_

Defines the warning and critical capacity thresholds. Can be global (applies to all departments)
or overridden per department. Department-specific settings take precedence.

| Property | Type | Constraints |
|----------|------|-------------|
| `Id` | `ThresholdConfigId` | Required, unique, GUID-based |
| `Scope` | `ThresholdScope` | `Global` or `Department` |
| `DepartmentId` | `Guid?` | Required when `Scope = Department`; `null` for global |
| `WarningThresholdPct` | `int` | Range 1–100; default 65 |
| `CriticalThresholdPct` | `int` | Range 1–100; must be > `WarningThresholdPct`; default 70 |
| `UpdatedAt` | `DateTime` (UTC) | Audit field |
| `UpdatedBy` | `EmployeeId` | Audit field; must be admin role |

**Invariants**

| # | Invariant | Source |
|---|-----------|--------|
| INV-210 | `CriticalThresholdPct > WarningThresholdPct` | Business rule |
| INV-211 | Both thresholds must be in range 1–100 | BR-125 |
| INV-212 | Only one active global config; one per department | Domain rule |
| INV-213 | Department config overrides global for all calculations in that department | BR-124 |

---

## Value Objects

### CapacityPeriod

```csharp
public record CapacityPeriod
{
    public DateOnly StartDate { get; }
    public DateOnly EndDate { get; }
    public CapacityGranularity Granularity { get; }

    // Returns each date (daily) or week-start date (weekly) in the period
    public IEnumerable<DateOnly> GetDates() { ... }

    public static CapacityPeriod CurrentMonth() { ... }
    public static CapacityPeriod Next90Days() { ... }   // BR-048
}
```

### CapacityColor

```csharp
// BR-040: heat-map colour thresholds
public enum CapacityColor
{
    Green,   // 0–50%
    Yellow,  // 51–64%
    Orange,  // 65–70% (Warning)
    Red      // >70%  (Critical)
}

public static CapacityColor FromPercentage(decimal pct, ThresholdConfig config) =>
    pct > config.CriticalThresholdPct ? CapacityColor.Red :
    pct >= config.WarningThresholdPct ? CapacityColor.Orange :
    pct > 50                          ? CapacityColor.Yellow :
                                        CapacityColor.Green;
```

### AlternativeDateSuggestion

```csharp
// BR-044b: suggested alternative dates when period is over-requested
public record AlternativeDateSuggestion(
    DateRange SuggestedRange,
    decimal ProjectedCapacityPercent,
    CapacityColor ProjectedColor
);
```

---

## Domain Events

```csharp
// Raised when capacity for a period crosses Warning threshold (65–70%)
public record CapacityWarningThresholdCrossed(
    Guid EventId, DateTime OccurredOn,
    Guid DepartmentId,
    DateOnly AffectedDate,
    decimal CapacityPercent,
    int EmployeeCount
) : IDomainEvent;

// Raised when capacity for a period crosses Critical threshold (>70%)
public record CapacityCriticalThresholdCrossed(
    Guid EventId, DateTime OccurredOn,
    Guid DepartmentId,
    DateOnly AffectedDate,
    decimal CapacityPercent,
    int EmployeeCount
) : IDomainEvent;

// Raised after recomputation to invalidate Redis cache entries
public record CapacitySnapshotInvalidated(
    Guid EventId, DateTime OccurredOn,
    OrganizationLevel Level,
    Guid LevelEntityId,
    DateOnly FromDate,
    DateOnly ToDate
) : IDomainEvent;
```

---

## Caching Strategy

:::mermaid
sequenceDiagram
    participant FE as Frontend
    participant API as API Handler
    participant L1 as IMemoryCache (5 min)
    participant L2 as Azure Redis (30 min)
    participant DB as Azure SQL

    FE->>API: GET /capacity?dept=X&from=Y&to=Z
    API->>L1: GetCapacitySnapshots(dept, from, to)
    alt L1 hit
        L1-->>API: Snapshots[]
    else L1 miss
        API->>L2: GetCapacitySnapshots(dept, from, to)
        alt L2 hit
            L2-->>API: Snapshots[]
            API->>L1: Set(snapshots, 5 min)
        else L2 miss
            API->>DB: SELECT * FROM CAPACITY_SNAPSHOTS ...
            DB-->>API: Snapshots[]
            API->>L2: Set(snapshots, 30 min)
            API->>L1: Set(snapshots, 5 min)
        end
    end
    API-->>FE: CapacityDto[]

    Note over L1,L2: Cache invalidated on VacationRequestApproved,<br/>VacationRequestCancelled, VacationRequestSubmitted
:::

---

## Database Schema (Azure SQL)

:::mermaid
erDiagram
    CAPACITY_SNAPSHOTS {
        uniqueidentifier Id PK
        date Date
        tinyint Level
        uniqueidentifier LevelEntityId
        int TotalEmployees
        int EmployeesOnVacation
        int EmployeesPending
        decimal_5_2 CapacityPercentage
        bit IsCritical
        bit IsWarning
        datetime2 ComputedAt
    }

    THRESHOLD_CONFIGS {
        uniqueidentifier Id PK
        tinyint Scope
        uniqueidentifier DepartmentId
        int WarningThresholdPct
        int CriticalThresholdPct
        datetime2 UpdatedAt
        uniqueidentifier UpdatedBy FK
    }

    CAPACITY_SNAPSHOTS }o--|| THRESHOLD_CONFIGS : "evaluated against"
:::

**Index strategy**

| Table | Index | Columns | Purpose |
|-------|-------|---------|---------|
| `CAPACITY_SNAPSHOTS` | `UQ_CS_Date_Level_Entity` | `Date`, `Level`, `LevelEntityId` | Upsert uniqueness |
| `CAPACITY_SNAPSHOTS` | `IX_CS_LevelEntity_DateRange` | `LevelEntityId`, `Date` | Calendar / heat-map range query |
| `CAPACITY_SNAPSHOTS` | `IX_CS_Critical_Date` | `IsCritical`, `Date` | Dashboard "over-requested periods in next 90 days" |
| `THRESHOLD_CONFIGS` | `UQ_TC_Scope_DepartmentId` | `Scope`, `DepartmentId` | Enforce one config per scope |

---

## CQRS Commands and Queries

### Commands (F-003)

```csharp
// Triggered by Service Bus event handlers on every approval/rejection/cancellation
public record RecomputeCapacitySnapshotsCommand(
    Guid LevelEntityId,
    OrganizationLevel Level,
    DateOnly FromDate,
    DateOnly ToDate
) : ICommand;

public record UpdateThresholdConfigCommand(
    ThresholdScope Scope,
    Guid? DepartmentId,
    int WarningThresholdPct,
    int CriticalThresholdPct,
    EmployeeId UpdatedBy
) : ICommand<ThresholdConfigId>;
```

### Queries (F-003)

```csharp
// Team calendar view — US-008
public record GetTeamCalendarQuery(
    EmployeeId RequestingUserId,
    OrganizationLevel Level,
    Guid LevelEntityId,
    DateOnly FromDate,
    DateOnly ToDate,
    CapacityGranularity Granularity = CapacityGranularity.Daily
) : IQuery<TeamCalendarDto>;

// Heat map — US-009
public record GetCapacityHeatMapQuery(
    EmployeeId RequestingUserId,
    Guid DepartmentId,
    DateOnly FromDate,
    DateOnly ToDate
) : IQuery<CapacityHeatMapDto>;

// Executive dashboard — US-010
public record GetDashboardSummaryQuery(
    EmployeeId RequestingUserId
) : IQuery<DashboardSummaryDto>;

// Drill-down cell detail — AC-009.6
public record GetCapacityCellDetailQuery(
    Guid LevelEntityId,
    OrganizationLevel Level,
    DateOnly Date
) : IQuery<CapacityCellDetailDto>;
```

---

## Ubiquitous Language

| Term | Definition | Context |
|------|------------|---------|
| **Capacity Percentage** | `(employees on vacation + pending) / total employees × 100` for a specific date and org level | CapacityManagement |
| **Heat Map** | Visual grid where each cell represents a day/week, coloured by capacity level | CapacityManagement |
| **Capacity Snapshot** | Pre-computed capacity value for a specific date and organizational level | CapacityManagement |
| **Warning Period** | A date where capacity is 65–70% (orange on heat map) | CapacityManagement |
| **Critical Period** | A date where capacity exceeds 70% (red on heat map) — BR-040 | CapacityManagement |
| **Threshold Config** | Configurable percentages defining warning and critical levels per department | CapacityManagement |
| **Alternative Dates** | System-suggested lower-capacity date ranges shown when a period is over-requested | CapacityManagement |
| **Organizational Level** | Granularity of a capacity query: Department, Project, or Team | CapacityManagement |
| **Cache Invalidation** | Process of marking cached snapshots stale after a vacation status change | CapacityManagement |

---

## Integration with Other Bounded Contexts

| Bounded Context | Direction | Mechanism | Data |
|-----------------|-----------|-----------|------|
| **VacationManagement (F-001)** | Inbound (events) | Service Bus consumer | `VacationRequestSubmitted`, `VacationRequestCancelled` → recompute snapshots |
| **ApprovalWorkflow (F-002)** | Inbound (events) | Service Bus consumer | `VacationRequestApprovedFinal` → recompute snapshots |
| **Organization (F-004)** | Inbound (read) | Dapper query | Employee headcount per dept/project to compute totals |
| **Notifications (F-006)** | Outbound (events) | Service Bus publisher | `CapacityWarningThresholdCrossed`, `CapacityCriticalThresholdCrossed` |
| **Reporting (F-007)** | Outbound (data) | Read model (Dapper) | Coverage report reads from `CAPACITY_SNAPSHOTS` |
