# Domain Model — F-001: Vacation Request Management

## Metadata

| Property    | Value                                           |
| ----------- | ----------------------------------------------- |
| Feature     | F-001 — Vacation Request Management             |
| Bounded Context | VacationManagement (Core Domain)            |
| Source      | UC-001 · UC-002 · UC-003 · US-001 · US-002 · US-003 |
| Created     | 2026-08-07                                      |
| Author      | Bolt DDD Agent                                  |
| Status      | Draft                                           |

---

## Bounded Context Overview

:::mermaid
flowchart TB
    subgraph VM["🟠 VacationManagement (Core Domain)"]
        VR["VacationRequest\n(Aggregate Root)"]
        ST["StatusTransition\n(Child Entity)"]
        VR -->|owns| ST
    end

    subgraph ORG["🔵 Organization (Supporting)"]
        EMP["Employee\n(Aggregate Root)"]
        DEPT["Department\n(Entity)"]
        PROJ["Project\n(Entity)"]
        BAL["VacationBalance\n(Value Object)"]
        EMP --> BAL
        EMP -->|belongs to| DEPT
        EMP -->|assigned to| PROJ
    end

    subgraph AW["🟣 ApprovalWorkflow (Core Domain)"]
        APPR["ApprovalRecord\n(Aggregate Root - F-002)"]
        DEL["Delegation\n(Entity - F-002)"]
    end

    subgraph NOTIF["⚪ Notifications (Supporting - F-006)"]
        EVT["Domain Events\n(Service Bus)"]
    end

    subgraph INT["🟢 Integration (Supporting)"]
        AD["AD Sync\n(F-004)"]
        SN["ServiceNow\n(F-005)"]
    end

    VR -->|references by ID| EMP
    APPR -->|references by ID| VR
    VM -->|publishes events to| EVT
    AD -->|syncs| EMP
    SN -->|exports| VR

    style VM fill:#fff3e0,stroke:#e65100,stroke-width:2px
    style ORG fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    style AW fill:#f3e5f5,stroke:#6a1b9a,stroke-width:2px
    style NOTIF fill:#f5f5f5,stroke:#616161,stroke-width:1px
    style INT fill:#e8f5e9,stroke:#2e7d32,stroke-width:1px
:::

---

## Aggregate Model

:::mermaid
classDiagram
    class VacationRequest {
        +VacationRequestId Id
        +EmployeeId EmployeeId
        +DateRange DateRange
        +VacationStatus Status
        +EmployeeNotes Notes
        +DateTime CreatedAt
        +DateTime? LastModifiedAt
        +IReadOnlyList~StatusTransition~ History
        +Submit(employeeId, dateRange, notes)$
        +Cancel(cancelledById)
        +TransitionTo(newStatus, changedById, reason)
        +HasOverlapWith(DateRange other) bool
    }

    class StatusTransition {
        +StatusTransitionId Id
        +VacationRequestId RequestId
        +VacationStatus? FromStatus
        +VacationStatus ToStatus
        +EmployeeId ChangedByEmployeeId
        +string ActorName
        +DateTime ChangedAt
        +string? Reason
    }

    class DateRange {
        <<Value Object>>
        +DateOnly StartDate
        +DateOnly EndDate
        +int TotalBusinessDays
        +IsValid() bool
        +OverlapsWith(DateRange other) bool
        +CalculateBusinessDays() int
    }

    class VacationStatus {
        <<Enumeration>>
        Pending
        PendingDepartmentApproval
        RejectedAtProjectLevel
        Approved
        Rejected
        Cancelled
    }

    class EmployeeNotes {
        <<Value Object>>
        +string? Value
        +int MaxLength = 500
        +IsEmpty() bool
    }

    class Employee {
        +EmployeeId Id
        +ExternalAdId ExternalId
        +FullName FullName
        +EmailAddress Email
        +DepartmentId DepartmentId
        +EmployeeId? ManagerId
        +EmployeeRole Role
        +bool IsActive
        +VacationBalance VacationBalance
        +bool CanApproveAtProjectLevel() bool
        +bool CanApproveAtDepartmentLevel() bool
    }

    class VacationBalance {
        <<Value Object>>
        +int TotalDays
        +int UsedDays
        +int PendingDays
        +int RemainingDays
        +bool HasSufficientBalance(int requestedDays) bool
    }

    class Department {
        +DepartmentId Id
        +string Name
        +EmployeeId ManagerId
        +int CapacityThresholdPercent = 70
    }

    class Project {
        +ProjectId Id
        +string Name
        +DepartmentId DepartmentId
        +EmployeeId ProjectManagerId
        +bool IsActive
    }

    class EmployeeRole {
        <<Enumeration>>
        Employee
        ProjectManager
        DepartmentManager
        Administrator
    }

    VacationRequest "1" *-- "0..*" StatusTransition : contains
    VacationRequest *-- DateRange : has
    VacationRequest *-- EmployeeNotes : has
    VacationRequest --> VacationStatus : current state
    Employee *-- VacationBalance : carries
    Employee --> EmployeeRole : plays
    Employee --> Department : belongs to
    Employee --> Project : assigned to
    VacationRequest --> Employee : owned by (ref by ID)
:::

---

## Entity Definitions

### VacationRequest _(Aggregate Root)_

The central aggregate of the `VacationManagement` bounded context. Owns the full lifecycle of a
single employee vacation request from submission through final resolution.

| Property | Type | Constraints |
|----------|------|-------------|
| `Id` | `VacationRequestId` | Required, unique, GUID-based |
| `EmployeeId` | `EmployeeId` | Required, FK reference |
| `DateRange` | `DateRange` VO | Required; StartDate < EndDate; StartDate ≥ today + 1 business day |
| `Status` | `VacationStatus` | Required; defaults to `Pending` on creation |
| `Notes` | `EmployeeNotes` VO | Optional; max 500 characters |
| `CreatedAt` | `DateTime` (UTC) | Set on creation; immutable |
| `LastModifiedAt` | `DateTime?` (UTC) | Updated on every status transition |
| `History` | `IReadOnlyList<StatusTransition>` | Append-only; owned collection |

**Invariants (enforced inside the aggregate)**

| # | Invariant | Source |
|---|-----------|--------|
| INV-001 | `DateRange.StartDate` must be ≥ today + 1 business day at creation time | BR-002 |
| INV-002 | `DateRange.StartDate` must be strictly before `DateRange.EndDate` | BR-001 |
| INV-003 | `Status` can only transition through the allowed state machine | BR-007 |
| INV-004 | A `Cancelled` or `Rejected` request cannot be cancelled again | BR-013 |
| INV-005 | `Notes.Value` must not exceed 500 characters when present | BR-005 |
| INV-006 | `History` always has at least one entry (the initial `null → Pending` transition) | UC-001 |

**Domain Methods**

```csharp
// Factory method — enforces INV-001, INV-002; raises VacationRequestSubmitted
VacationRequest.Submit(EmployeeId, DateRange, EmployeeNotes?) : VacationRequest

// Raises VacationRequestCancelled; requires owning employee
void Cancel(EmployeeId cancelledById)

// Internal helper called by approval handlers (F-002)
void TransitionTo(VacationStatus newStatus, EmployeeId changedById, string? reason)

// Pure query — used for overlap validation
bool HasOverlapWith(DateRange other)
```

**Domain Events raised**

| Event | Trigger |
|-------|---------|
| `VacationRequestSubmitted` | On successful `Submit()` |
| `VacationRequestCancelled` | On successful `Cancel()` |

---

### StatusTransition _(Child Entity of VacationRequest)_

Immutable audit record of every status change on a `VacationRequest`. Append-only;
transitions are never updated or deleted (compliance requirement: 7-year retention).

| Property | Type | Constraints |
|----------|------|-------------|
| `Id` | `StatusTransitionId` | Required, unique, GUID-based |
| `RequestId` | `VacationRequestId` | Required, FK to parent aggregate |
| `FromStatus` | `VacationStatus?` | `null` for the initial Pending entry |
| `ToStatus` | `VacationStatus` | Required |
| `ChangedByEmployeeId` | `EmployeeId` | Required; identity of the actor |
| `ActorName` | `string` | Denormalized for audit readability (snapshot at transition time) |
| `ChangedAt` | `DateTime` (UTC) | Required; set by the domain, not the caller |
| `Reason` | `string?` | Mandatory for Rejected/Cancelled transitions; optional otherwise |

**Invariants**

| # | Invariant | Source |
|---|-----------|--------|
| INV-010 | Transition record is immutable after creation | Audit / Compliance |
| INV-011 | `Reason` must be present (min 10 chars) when `ToStatus` is `Rejected` | BR-017 |
| INV-012 | `Reason` is optional when `ToStatus` is `Cancelled` | BR-011 |

---

### Employee _(Aggregate Root — Organization BC)_

Represents a corporate employee synchronized nightly from Active Directory (F-004). Scoped to
the `Organization` bounded context; consumed in `VacationManagement` as a read projection.

| Property | Type | Constraints |
|----------|------|-------------|
| `Id` | `EmployeeId` | Required, unique, GUID-based |
| `ExternalId` | `ExternalAdId` | Required; AD Object ID; unique |
| `FullName` | `FullName` VO | Required; non-empty |
| `Email` | `EmailAddress` VO | Required; valid email; unique |
| `DepartmentId` | `DepartmentId` | Required; FK to Department |
| `ManagerId` | `EmployeeId?` | Optional; direct manager (primary PM) |
| `Role` | `EmployeeRole` | Required; defaults to `Employee` on first sync |
| `IsActive` | `bool` | `false` if employee removed from AD (soft-delete only) |
| `VacationBalance` | `VacationBalance` VO | Updated on ServiceNow import (F-005) |

**Invariants**

| # | Invariant | Source |
|---|-----------|--------|
| INV-020 | Employees are never hard-deleted; only deactivated (`IsActive = false`) | BR-056 |
| INV-021 | `Email` must be unique across all active employees | Domain rule |
| INV-022 | `ExternalId` must be unique across all employees | AD sync rule |
| INV-023 | `Role` assignment is manual or via AD Group; defaults to `Employee` on sync | BR-058 |

---

### Department _(Entity — Organization BC)_

Organizational unit grouping employees and projects. Owns the capacity threshold for the 70%
over-request alert (F-003).

| Property | Type | Constraints |
|----------|------|-------------|
| `Id` | `DepartmentId` | Required, unique, GUID-based |
| `Name` | `string` | Required; non-empty; max 100 chars |
| `ManagerId` | `EmployeeId` | Required; FK to Employee with `DepartmentManager` role |
| `CapacityThresholdPercent` | `int` | Default 70; range 1–100; configurable (F-007 admin) |

---

### Project _(Entity — Organization BC)_

Work unit within a department. The primary approval unit for Level-1 approval (F-002).

| Property | Type | Constraints |
|----------|------|-------------|
| `Id` | `ProjectId` | Required, unique, GUID-based |
| `Name` | `string` | Required; non-empty; max 100 chars |
| `DepartmentId` | `DepartmentId` | Required; FK to Department |
| `ProjectManagerId` | `EmployeeId` | Required; FK to Employee with `ProjectManager` role |
| `IsActive` | `bool` | Inactive projects do not route approval requests |

---

## Value Objects

### DateRange

Encapsulates the vacation period and its business-day calculation. Immutable.

```csharp
public record DateRange
{
    public DateOnly StartDate { get; }
    public DateOnly EndDate { get; }
    public int TotalBusinessDays { get; }   // computed: Mon–Fri, inclusive

    // Factory — validates StartDate < EndDate; throws DomainException otherwise
    public static DateRange Create(DateOnly start, DateOnly end) { ... }

    public bool OverlapsWith(DateRange other) =>
        StartDate <= other.EndDate && EndDate >= other.StartDate;

    // Counts Mon–Fri days between start and end (inclusive) — BR-003
    private static int CalculateBusinessDays(DateOnly start, DateOnly end) { ... }
}
```

**Business rules encoded**

| Rule | Implementation |
|------|---------------|
| BR-001: StartDate and EndDate required | Both parameters mandatory in `Create()` |
| BR-003: Business days = Mon–Fri only | `CalculateBusinessDays()` skips Saturday/Sunday |
| BR-004: No overlap allowed | `OverlapsWith()` used during submission validation |

---

### VacationBalance

Snapshot of an employee's remaining vacation entitlement. Updated by the ServiceNow import
job (F-005). Immutable value object.

```csharp
public record VacationBalance
{
    public int TotalDays { get; }       // Annual entitlement from ServiceNow
    public int UsedDays { get; }        // Approved + taken (historical)
    public int PendingDays { get; }     // Sum of open Pending requests
    public int RemainingDays => TotalDays - UsedDays - PendingDays;

    // BR-006c: balance check before submission
    public bool HasSufficientBalance(int requestedDays) =>
        RemainingDays >= requestedDays;
}
```

---

### EmployeeNotes

Wraps the optional free-text field on a vacation request.

```csharp
public record EmployeeNotes
{
    public const int MaxLength = 500;   // BR-005
    public string? Value { get; }
    public bool IsEmpty => string.IsNullOrWhiteSpace(Value);

    // Throws DomainException if Value exceeds MaxLength
    public static EmployeeNotes Create(string? value) { ... }
}
```

---

### FullName

```csharp
public record FullName(string FirstName, string LastName)
{
    public string DisplayName => $"{FirstName} {LastName}";
}
```

---

### EmailAddress

```csharp
public record EmailAddress
{
    public string Value { get; }
    // Validates RFC-5322 format; throws DomainException if invalid
    public static EmailAddress Create(string value) { ... }
}
```

---

## Enumerations

### VacationStatus

```csharp
public enum VacationStatus
{
    Pending,                    // Submitted; awaiting project-level approval
    PendingDepartmentApproval,  // PM approved; awaiting DM approval
    RejectedAtProjectLevel,     // PM rejected; employee may appeal to DM
    Approved,                   // DM final approval — fully approved
    Rejected,                   // DM final rejection — fully rejected
    Cancelled                   // Cancelled by employee
}
```

### EmployeeRole

```csharp
public enum EmployeeRole
{
    Employee,           // Can submit and cancel own requests
    ProjectManager,     // Level-1 approval authority
    DepartmentManager,  // Level-2 approval authority; escalation recipient
    Administrator       // System configuration; read all data
}
```

---

## Status Machine

:::mermaid
stateDiagram-v2
    [*] --> Pending : Submit() ✔

    Pending --> PendingDepartmentApproval : PM Approves
    Pending --> RejectedAtProjectLevel : PM Rejects (reason required)
    Pending --> Cancelled : Employee Cancels

    PendingDepartmentApproval --> Approved : DM Approves ✔
    PendingDepartmentApproval --> Rejected : DM Rejects (reason required)
    PendingDepartmentApproval --> Cancelled : Employee Cancels

    RejectedAtProjectLevel --> PendingDepartmentApproval : Employee Appeals
    RejectedAtProjectLevel --> Approved : DM Overrides PM Rejection
    RejectedAtProjectLevel --> Rejected : DM Confirms PM Rejection

    Approved --> Cancelled : Employee Cancels (confirmation required)

    Approved --> [*]
    Rejected --> [*]
    Cancelled --> [*]

    note right of Pending
        BR-004: No overlapping requests
        BR-006c: Balance check
    end note
    note right of Approved
        Eligible for ServiceNow export
        Capacity snapshot updated
    end note
:::

**Allowed transitions table**

| From Status | To Status | Actor | Condition |
|-------------|-----------|-------|-----------|
| _(none)_ | `Pending` | Employee | Submit validation passes |
| `Pending` | `PendingDepartmentApproval` | Project Manager / Delegate | — |
| `Pending` | `RejectedAtProjectLevel` | Project Manager / Delegate | Reason required (min 10 chars) |
| `Pending` | `Cancelled` | Employee (owner only) | — |
| `PendingDepartmentApproval` | `Approved` | Department Manager / Delegate | — |
| `PendingDepartmentApproval` | `Rejected` | Department Manager / Delegate | Reason required |
| `PendingDepartmentApproval` | `Cancelled` | Employee (owner only) | Confirmation dialog shown |
| `RejectedAtProjectLevel` | `PendingDepartmentApproval` | Employee (appeal) | — |
| `RejectedAtProjectLevel` | `Approved` | Department Manager | DM override |
| `RejectedAtProjectLevel` | `Rejected` | Department Manager | Confirms PM decision |
| `Approved` | `Cancelled` | Employee (owner only) | Confirmation required (BR-012) |

---

## Domain Events

All domain events implement `IDomainEvent` (see constitution CQRS binding contracts).

```csharp
public interface IDomainEvent
{
    Guid EventId { get; }
    DateTime OccurredOn { get; }
}
```

### VacationRequestSubmitted

Raised when an employee successfully submits a new vacation request.
Consumed by: Notification handler (F-006 → email to PM), Capacity service (F-003).

```csharp
public record VacationRequestSubmitted(
    Guid EventId,
    DateTime OccurredOn,
    VacationRequestId RequestId,
    EmployeeId EmployeeId,
    string EmployeeFullName,
    DateRange DateRange,
    int TotalBusinessDays
) : IDomainEvent;
```

### VacationRequestCancelled

Raised when an employee cancels a request (Pending or Approved status).
Consumed by: Notification handler (F-006 → email to approvers), Capacity service (F-003),
ServiceNow removal trigger (F-005 — only if request was previously exported).

```csharp
public record VacationRequestCancelled(
    Guid EventId,
    DateTime OccurredOn,
    VacationRequestId RequestId,
    EmployeeId EmployeeId,
    EmployeeId CancelledByEmployeeId,
    DateRange DateRange,
    VacationStatus PreviousStatus,  // to determine if ServiceNow removal needed
    bool WasApproved
) : IDomainEvent;
```

> **Note:** Approval domain events (`VacationRequestApprovedAtProjectLevel`,
> `VacationRequestApproved`, `VacationRequestRejected`) are raised by the
> `ApprovalWorkflow` bounded context (F-002).

---

## Database Schema (Azure SQL)

:::mermaid
erDiagram
    VACATION_REQUESTS {
        uniqueidentifier Id PK
        uniqueidentifier EmployeeId FK
        date StartDate
        date EndDate
        int TotalBusinessDays
        tinyint Status
        nvarchar_500 Notes
        datetime2 CreatedAt
        datetime2 LastModifiedAt
    }

    STATUS_TRANSITIONS {
        uniqueidentifier Id PK
        uniqueidentifier RequestId FK
        tinyint FromStatus
        tinyint ToStatus
        uniqueidentifier ChangedByEmployeeId FK
        nvarchar_200 ActorName
        datetime2 ChangedAt
        nvarchar_1000 Reason
    }

    EMPLOYEES {
        uniqueidentifier Id PK
        nvarchar_200 ExternalAdId
        nvarchar_100 FirstName
        nvarchar_100 LastName
        nvarchar_256 Email
        uniqueidentifier DepartmentId FK
        uniqueidentifier ManagerId FK
        tinyint Role
        bit IsActive
        int VacationTotalDays
        int VacationUsedDays
        int VacationPendingDays
        datetime2 LastSyncedAt
    }

    DEPARTMENTS {
        uniqueidentifier Id PK
        nvarchar_100 Name
        uniqueidentifier ManagerId FK
        int CapacityThresholdPercent
    }

    PROJECTS {
        uniqueidentifier Id PK
        nvarchar_100 Name
        uniqueidentifier DepartmentId FK
        uniqueidentifier ProjectManagerId FK
        bit IsActive
    }

    EMPLOYEE_PROJECTS {
        uniqueidentifier EmployeeId PK,FK
        uniqueidentifier ProjectId PK,FK
        bit IsPrimary
    }

    VACATION_REQUESTS ||--o{ STATUS_TRANSITIONS : "has history"
    EMPLOYEES ||--o{ VACATION_REQUESTS : "submits"
    EMPLOYEES ||--o{ STATUS_TRANSITIONS : "acts on"
    DEPARTMENTS ||--o{ EMPLOYEES : "contains"
    DEPARTMENTS ||--o{ PROJECTS : "contains"
    PROJECTS ||--o{ EMPLOYEE_PROJECTS : "has"
    EMPLOYEES ||--o{ EMPLOYEE_PROJECTS : "belongs to"
:::

**Index strategy**

| Table | Index | Columns | Purpose |
|-------|-------|---------|---------|
| `VACATION_REQUESTS` | `IX_VR_EmployeeId_Status` | `EmployeeId`, `Status` | My Requests query |
| `VACATION_REQUESTS` | `IX_VR_DateRange` | `StartDate`, `EndDate`, `Status` | Overlap detection; calendar |
| `STATUS_TRANSITIONS` | `IX_ST_RequestId_ChangedAt` | `RequestId`, `ChangedAt` | Timeline query per request |
| `EMPLOYEES` | `IX_EMP_ExternalAdId` | `ExternalAdId` | AD sync upsert lookup |
| `EMPLOYEES` | `UQ_EMP_Email` | `Email` | Uniqueness enforcement |
| `EMPLOYEES` | `IX_EMP_DepartmentId_IsActive` | `DepartmentId`, `IsActive` | Department capacity queries |

---

## CQRS Commands and Queries

Commands and queries follow the constitution binding contracts exactly.

### Commands (F-001)

```csharp
// UC-001 — US-001
public record SubmitVacationRequestCommand(
    EmployeeId EmployeeId,
    DateOnly StartDate,
    DateOnly EndDate,
    string? Notes
) : ICommand<VacationRequestId>;

// UC-003 — US-003
public record CancelVacationRequestCommand(
    VacationRequestId RequestId,
    EmployeeId CancelledByEmployeeId
) : ICommand;
```

### Queries (F-001)

```csharp
// UC-002 — US-002: My Requests list
public record GetMyVacationRequestsQuery(
    EmployeeId EmployeeId,
    VacationStatus? StatusFilter,
    DateOnly? FromDate,
    DateOnly? ToDate,
    int Page = 1,
    int PageSize = 20
) : IQuery<PagedResult<VacationRequestSummaryDto>>;

// UC-002 — Request detail with status timeline
public record GetVacationRequestDetailQuery(
    VacationRequestId RequestId,
    EmployeeId RequestingEmployeeId  // security: must be owner
) : IQuery<VacationRequestDetailDto>;
```

---

## Ubiquitous Language

| Term | Definition | Context |
|------|------------|---------|
| **Vacation Request** | A formal employee petition for time off, tracked from submission to resolution | VacationManagement |
| **Business Day** | A weekday (Monday–Friday); weekends are excluded from all day counts | All |
| **Pending** | A request submitted but not yet acted on by the Project Manager | VacationManagement |
| **Pending Department Approval** | A request approved at project level, awaiting DM decision | VacationManagement |
| **Rejected at Project Level** | A PM rejection that is not final; employee may appeal to DM | VacationManagement |
| **Approved** | A request with both project-level and department-level approval | VacationManagement |
| **Rejected** | A final department-level rejection | VacationManagement |
| **Cancelled** | A request withdrawn by the employee | VacationManagement |
| **Date Range** | The period of a vacation request, from start date to end date (both inclusive) | VacationManagement |
| **Total Days** | Count of business days within a date range (Mon–Fri only) | VacationManagement |
| **Vacation Balance** | An employee's remaining entitlement = Total − Used − Pending days | Organization |
| **Status Transition** | An immutable record of a change in request status, capturing who acted and when | VacationManagement |
| **Appeal** | Employee action to escalate a PM rejection to the DM for reconsideration | ApprovalWorkflow |
| **Overlap** | Two date ranges are overlapping when they share at least one calendar day | VacationManagement |
| **Capacity Threshold** | The department-configured percentage (default 70%) above which a period is flagged as over-requested | CapacityManagement |

---

## Open Issues / Design Decisions

| ID | Issue | Resolution |
|----|-------|------------|
| CL-002 | Maximum consecutive vacation days | None — no maximum limit (resolved) |
| CL-003 | Blackout periods | None in Phase 1 (resolved) |
| CL-013 | Vacation balance source | ServiceNow-imported balance (resolved) |
| TBD | Multi-project employee primary project | Primary project flag in `EMPLOYEE_PROJECTS.IsPrimary` |
| TBD | Self-approval (PM who is also DM) | Allowed — BR-019a; system skips L1 and uses L2 only |

---

## Integration with Other Bounded Contexts

| Bounded Context | Direction | Mechanism | Data |
|-----------------|-----------|-----------|------|
| **ApprovalWorkflow (F-002)** | Inbound | Direct call via CQRS dispatcher | Calls `TransitionTo()` on VacationRequest |
| **CapacityManagement (F-003)** | Inbound (event-driven) | Subscribes to `VacationRequestSubmitted` / `VacationRequestCancelled` | Updates capacity snapshots |
| **Notifications (F-006)** | Inbound (event-driven) | Subscribes to Service Bus events | Sends email on submission / cancellation |
| **ServiceNow (F-005)** | Outbound | Background job reads Approved requests | Exports `Status = Approved` records nightly |
| **Identity / AD Sync (F-004)** | Inbound | Nightly sync populates Employee entities | Updates Employee, VacationBalance |
