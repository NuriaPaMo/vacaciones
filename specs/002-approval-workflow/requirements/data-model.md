# Domain Model — F-002: Approval Workflow

## Metadata

| Property        | Value                                            |
| --------------- | ------------------------------------------------ |
| Feature         | F-002 — Approval Workflow                        |
| Bounded Context | ApprovalWorkflow (Core Domain)                   |
| Source          | UC-004 · UC-005 · UC-006 · UC-007 · US-004–007  |
| Created         | 2026-08-07                                       |
| Author          | Bolt DDD Agent                                   |
| Status          | Draft                                            |

---

## Bounded Context Overview

:::mermaid
flowchart TB
    subgraph AW["🟣 ApprovalWorkflow (Core Domain)"]
        WF["ApprovalWorkflow\n(Aggregate Root)"]
        AS["ApprovalStep\n(Child Entity)"]
        DEL["Delegation\n(Aggregate Root)"]
        ESC["EscalationEvent\n(Entity)"]
        WF -->|owns| AS
    end

    subgraph VM["🟠 VacationManagement (Core Domain - F-001)"]
        VR["VacationRequest\n(Aggregate Root)"]
    end

    subgraph ORG["🔵 Organization (Supporting - F-004)"]
        EMP["Employee\n(Aggregate Root)"]
    end

    subgraph NOTIF["⚪ Notifications (F-006)"]
        EVT["Domain Events\n(Service Bus)"]
    end

    WF -->|references by ID| VR
    WF -->|transitions status on| VR
    AS -->|references by ID| EMP
    DEL -->|DelegatorId| EMP
    DEL -->|DelegateId| EMP
    ESC -->|references by ID| WF
    AW -->|publishes events to| EVT

    style AW fill:#f3e5f5,stroke:#6a1b9a,stroke-width:2px
    style VM fill:#fff3e0,stroke:#e65100,stroke-width:2px
    style ORG fill:#e3f2fd,stroke:#1565c0,stroke-width:1px
    style NOTIF fill:#f5f5f5,stroke:#616161,stroke-width:1px
:::

---

## Aggregate Model

:::mermaid
classDiagram
    class ApprovalWorkflow {
        +ApprovalWorkflowId Id
        +VacationRequestId RequestId
        +ApprovalLevel CurrentLevel
        +IReadOnlyList~ApprovalStep~ Steps
        +DateTime CreatedAt
        +DateTime? CompletedAt
        +ApproveAtProjectLevel(approverId, delegationId?)$
        +RejectAtProjectLevel(approverId, reason, delegationId?)$
        +ApproveAtDepartmentLevel(approverId, delegationId?)$
        +RejectAtDepartmentLevel(approverId, reason, delegationId?)$
        +RecordEscalation(escalationType)$
        +IsCompleted() bool
    }

    class ApprovalStep {
        +ApprovalStepId Id
        +ApprovalWorkflowId WorkflowId
        +ApprovalLevel Level
        +ApprovalDecision Decision
        +EmployeeId ApproverId
        +string ApproverName
        +DateTime ActedAt
        +string? Reason
        +bool IsDelegate
        +EmployeeId? OriginalApproverId
        +string? OriginalApproverName
    }

    class Delegation {
        +DelegationId Id
        +EmployeeId DelegatorId
        +EmployeeId DelegateId
        +DelegationScope Scope
        +DateOnly StartDate
        +DateOnly? EndDate
        +bool IsActive
        +bool IsRevoked
        +DateTime CreatedAt
        +DateTime? RevokedAt
        +EmployeeId? RevokedById
        +bool IsEffectiveOn(DateOnly date) bool
        +Revoke(revokedById)$
    }

    class EscalationEvent {
        +EscalationEventId Id
        +ApprovalWorkflowId WorkflowId
        +VacationRequestId RequestId
        +EscalationType Type
        +ApprovalLevel Level
        +EmployeeId TargetEmployeeId
        +DateTime TriggeredAt
        +DateTime? ResolvedAt
        +bool IsResolved
    }

    class ApprovalLevel {
        <<Enumeration>>
        Project = 1
        Department = 2
    }

    class ApprovalDecision {
        <<Enumeration>>
        Approved
        Rejected
    }

    class DelegationScope {
        <<Enumeration>>
        ProjectLevel
        DepartmentLevel
    }

    class EscalationType {
        <<Enumeration>>
        Reminder
        DirectEscalation
    }

    ApprovalWorkflow "1" *-- "0..*" ApprovalStep : contains
    ApprovalWorkflow --> ApprovalLevel : currentLevel
:::

---

## Entity Definitions

### ApprovalWorkflow _(Aggregate Root)_

Manages the two-level approval lifecycle for a single `VacationRequest`. Created when a vacation
request is submitted. Owns all approval steps and orchestrates status transitions back onto the
`VacationRequest` aggregate via CQRS.

| Property | Type | Constraints |
|----------|------|-------------|
| `Id` | `ApprovalWorkflowId` | Required, unique, GUID-based |
| `RequestId` | `VacationRequestId` | Required, FK reference to VacationRequest |
| `CurrentLevel` | `ApprovalLevel` | Required; starts at `Project` on creation |
| `Steps` | `IReadOnlyList<ApprovalStep>` | Append-only; each decision adds one step |
| `CreatedAt` | `DateTime` (UTC) | Set on creation; immutable |
| `CompletedAt` | `DateTime?` (UTC) | Set when workflow reaches terminal state |

**Invariants**

| # | Invariant | Source |
|---|-----------|--------|
| INV-101 | Only one active (non-completed) workflow per `VacationRequest` | BR-015 |
| INV-102 | `ApprovalStep` at Level 1 required before Level 2 can act (unless escalation bypass) | BR-020, BR-021 |
| INV-103 | Rejection reason must be ≥ 10 characters | BR-017 |
| INV-104 | A PM can only act on requests from employees in their assigned projects | BR-018 |
| INV-105 | A DM can act on all requests in their department | BR-023 |
| INV-106 | Self-approval is permitted when PM is also DM (both levels resolved in single step) | BR-019a |

**Domain Methods**

```csharp
// Each method validates authority, records ApprovalStep, transitions VacationRequest status,
// publishes domain event, and sets CompletedAt if terminal state reached.

void ApproveAtProjectLevel(EmployeeId approverId, DelegationId? delegationId = null)
void RejectAtProjectLevel(EmployeeId approverId, string reason, DelegationId? delegationId = null)
void ApproveAtDepartmentLevel(EmployeeId approverId, DelegationId? delegationId = null)
void RejectAtDepartmentLevel(EmployeeId approverId, string reason, DelegationId? delegationId = null)
// Used by employee appeal path — returns to DM queue without a new ApprovalStep
void EscalateToDepartment(EscalationType type, EmployeeId targetEmployeeId)
bool IsCompleted()   // true when Approved, Rejected, or Cancelled
```

---

### ApprovalStep _(Child Entity of ApprovalWorkflow)_

Immutable record of a single approval action. Captures the delegated-or-direct identity for
full audit traceability. Each workflow may have zero (pending), one, or two steps (one per level).

| Property | Type | Constraints |
|----------|------|-------------|
| `Id` | `ApprovalStepId` | Required, unique, GUID-based |
| `WorkflowId` | `ApprovalWorkflowId` | Required, FK to parent |
| `Level` | `ApprovalLevel` | Required: Project or Department |
| `Decision` | `ApprovalDecision` | Required: Approved or Rejected |
| `ApproverId` | `EmployeeId` | Actual actor (may be delegate) |
| `ApproverName` | `string` | Denormalized snapshot for audit |
| `ActedAt` | `DateTime` (UTC) | Required; set by domain |
| `Reason` | `string?` | Required when `Decision = Rejected` (≥ 10 chars) |
| `IsDelegate` | `bool` | `true` when delegate acted on behalf of original |
| `OriginalApproverId` | `EmployeeId?` | Set when `IsDelegate = true` |
| `OriginalApproverName` | `string?` | Denormalized snapshot for audit |

---

### Delegation _(Aggregate Root)_

Represents the temporary or permanent transfer of approval authority from one approver to
another. Scoped to project-level or department-level; cannot overlap with another active
delegation for the same delegator.

| Property | Type | Constraints |
|----------|------|-------------|
| `Id` | `DelegationId` | Required, unique, GUID-based |
| `DelegatorId` | `EmployeeId` | Required; PM or DM granting authority |
| `DelegateId` | `EmployeeId` | Required; designated backup from same project/dept |
| `Scope` | `DelegationScope` | Required: `ProjectLevel` or `DepartmentLevel` |
| `StartDate` | `DateOnly` | Required; when delegation becomes effective |
| `EndDate` | `DateOnly?` | Optional; `null` = permanent until revoked |
| `IsActive` | `bool` | `true` when active; `false` after expiry or revocation |
| `IsRevoked` | `bool` | `true` when manually revoked before end date |
| `CreatedAt` | `DateTime` (UTC) | Set on creation; immutable |
| `RevokedAt` | `DateTime?` (UTC) | Set when revoked |
| `RevokedById` | `EmployeeId?` | Who revoked it (delegator or admin) |

**Invariants**

| # | Invariant | Source |
|---|-----------|--------|
| INV-110 | Max one active delegation per delegator per scope at any time | BR-028 |
| INV-111 | Circular delegation disallowed (`A → B` and `B → A` simultaneously) | BR-027 |
| INV-112 | Delegate must be a designated backup from the same project/department | BR-026 |
| INV-113 | `EndDate`, when set, must be ≥ `StartDate` | Domain rule |

---

### EscalationEvent _(Entity)_

Records when the background escalation job triggered a reminder or direct escalation for a
pending workflow. Resolved when the approver finally acts on the request.

| Property | Type | Constraints |
|----------|------|-------------|
| `Id` | `EscalationEventId` | Required, unique, GUID-based |
| `WorkflowId` | `ApprovalWorkflowId` | Required |
| `RequestId` | `VacationRequestId` | Denormalized for efficient queries |
| `Type` | `EscalationType` | `Reminder` (day 3) or `DirectEscalation` (day 5) |
| `Level` | `ApprovalLevel` | Which level is being escalated |
| `TargetEmployeeId` | `EmployeeId` | Who received the escalation alert |
| `TriggeredAt` | `DateTime` (UTC) | When the escalation job fired |
| `ResolvedAt` | `DateTime?` (UTC) | When the request was finally acted on |
| `IsResolved` | `bool` | `true` after any approval/rejection following this event |

---

## Value Objects

### DelegationPeriod

```csharp
public record DelegationPeriod
{
    public DateOnly StartDate { get; }
    public DateOnly? EndDate { get; }    // null = permanent

    public bool IsPermanent => EndDate is null;

    // BR-025: a delegation is effective if today falls within its period
    public bool IsEffectiveOn(DateOnly date) =>
        date >= StartDate && (EndDate is null || date <= EndDate);
}
```

### EscalationThreshold

```csharp
// Configurable per department; defaults from BR-030
public record EscalationThreshold
{
    public int ReminderAfterDays { get; }    // default 3
    public int EscalationAfterDays { get; }  // default 5

    // BR-034: only business days count for escalation
    public bool ShouldSendReminder(int pendingBusinessDays) =>
        pendingBusinessDays >= ReminderAfterDays;
    public bool ShouldEscalate(int pendingBusinessDays) =>
        pendingBusinessDays >= EscalationAfterDays;
}
```

---

## Domain Events

```csharp
// Raised by ApprovalWorkflow.ApproveAtProjectLevel()
public record VacationRequestApprovedAtProjectLevel(
    Guid EventId, DateTime OccurredOn,
    VacationRequestId RequestId,
    EmployeeId ApproverId,
    bool ActedAsDelegate,
    EmployeeId? OriginalApproverId
) : IDomainEvent;

// Raised by ApprovalWorkflow.ApproveAtDepartmentLevel()
public record VacationRequestApprovedFinal(
    Guid EventId, DateTime OccurredOn,
    VacationRequestId RequestId,
    EmployeeId ApproverId,
    bool ActedAsDelegate
) : IDomainEvent;

// Raised by ApprovalWorkflow.RejectAtProjectLevel()
public record VacationRequestRejectedAtProjectLevel(
    Guid EventId, DateTime OccurredOn,
    VacationRequestId RequestId,
    EmployeeId ApproverId,
    string Reason
) : IDomainEvent;

// Raised by ApprovalWorkflow.RejectAtDepartmentLevel()
public record VacationRequestRejectedFinal(
    Guid EventId, DateTime OccurredOn,
    VacationRequestId RequestId,
    EmployeeId ApproverId,
    string Reason
) : IDomainEvent;

// Raised by ApprovalWorkflow.EscalateToDepartment()
public record ApprovalEscalationTriggered(
    Guid EventId, DateTime OccurredOn,
    VacationRequestId RequestId,
    EscalationType EscalationType,
    EmployeeId TargetEmployeeId
) : IDomainEvent;
```

---

## Approval State Machine (F-002 view)

:::mermaid
stateDiagram-v2
    direction LR
    [*] --> PendingProjectApproval : Workflow created on VR.Submit()

    PendingProjectApproval --> PendingDeptApproval : PM / Delegate Approves
    PendingProjectApproval --> RejectedAtProjectLevel : PM / Delegate Rejects (reason)
    PendingProjectApproval --> EscalatedToDept : Day 5 — DM can bypass PM

    EscalatedToDept --> PendingDeptApproval : Treated same as PM-approved

    RejectedAtProjectLevel --> PendingDeptApproval : Employee Appeals

    PendingDeptApproval --> Completed_Approved : DM / Delegate Approves ✔
    PendingDeptApproval --> Completed_Rejected : DM / Delegate Rejects

    PendingProjectApproval --> Completed_Cancelled : VacationRequest Cancelled
    PendingDeptApproval --> Completed_Cancelled : VacationRequest Cancelled
    RejectedAtProjectLevel --> Completed_Cancelled : VacationRequest Cancelled

    Completed_Approved --> [*]
    Completed_Rejected --> [*]
    Completed_Cancelled --> [*]

    note right of PendingProjectApproval
        Day 3 → Reminder email to PM
        Day 5 → DM escalation alert
        BR-030, BR-034
    end note
:::

---

## Database Schema (Azure SQL)

:::mermaid
erDiagram
    APPROVAL_WORKFLOWS {
        uniqueidentifier Id PK
        uniqueidentifier RequestId FK
        tinyint CurrentLevel
        datetime2 CreatedAt
        datetime2 CompletedAt
    }

    APPROVAL_STEPS {
        uniqueidentifier Id PK
        uniqueidentifier WorkflowId FK
        tinyint Level
        tinyint Decision
        uniqueidentifier ApproverId FK
        nvarchar_200 ApproverName
        datetime2 ActedAt
        nvarchar_1000 Reason
        bit IsDelegate
        uniqueidentifier OriginalApproverId
        nvarchar_200 OriginalApproverName
    }

    DELEGATIONS {
        uniqueidentifier Id PK
        uniqueidentifier DelegatorId FK
        uniqueidentifier DelegateId FK
        tinyint Scope
        date StartDate
        date EndDate
        bit IsActive
        bit IsRevoked
        datetime2 CreatedAt
        datetime2 RevokedAt
        uniqueidentifier RevokedById
    }

    ESCALATION_EVENTS {
        uniqueidentifier Id PK
        uniqueidentifier WorkflowId FK
        uniqueidentifier RequestId FK
        tinyint Type
        tinyint Level
        uniqueidentifier TargetEmployeeId FK
        datetime2 TriggeredAt
        datetime2 ResolvedAt
        bit IsResolved
    }

    APPROVAL_WORKFLOWS ||--o{ APPROVAL_STEPS : "records"
    APPROVAL_WORKFLOWS ||--o{ ESCALATION_EVENTS : "triggers"
:::

**Index strategy**

| Table | Index | Columns | Purpose |
|-------|-------|---------|---------|
| `APPROVAL_WORKFLOWS` | `UQ_AW_RequestId` | `RequestId` | One workflow per request |
| `APPROVAL_WORKFLOWS` | `IX_AW_CurrentLevel_Completed` | `CurrentLevel`, `CompletedAt` | Escalation job query |
| `DELEGATIONS` | `IX_DEL_DelegatorId_Active` | `DelegatorId`, `IsActive` | Active delegation lookup |
| `DELEGATIONS` | `IX_DEL_DelegateId_Active` | `DelegateId`, `IsActive` | Check if acting as delegate |
| `ESCALATION_EVENTS` | `IX_ESC_WorkflowId_Resolved` | `WorkflowId`, `IsResolved` | Resolve on workflow completion |

---

## CQRS Commands and Queries

### Commands (F-002)

```csharp
public record ApproveAtProjectLevelCommand(
    VacationRequestId RequestId,
    EmployeeId ApproverId,
    DelegationId? DelegationId = null
) : ICommand;

public record RejectAtProjectLevelCommand(
    VacationRequestId RequestId,
    EmployeeId ApproverId,
    string Reason,
    DelegationId? DelegationId = null
) : ICommand;

public record ApproveAtDepartmentLevelCommand(
    VacationRequestId RequestId,
    EmployeeId ApproverId,
    DelegationId? DelegationId = null
) : ICommand;

public record RejectAtDepartmentLevelCommand(
    VacationRequestId RequestId,
    EmployeeId ApproverId,
    string Reason,
    DelegationId? DelegationId = null
) : ICommand;

public record AppealProjectRejectionCommand(
    VacationRequestId RequestId,
    EmployeeId EmployeeId   // must be the request owner
) : ICommand;

public record CreateDelegationCommand(
    EmployeeId DelegatorId,
    EmployeeId DelegateId,
    DelegationScope Scope,
    DateOnly StartDate,
    DateOnly? EndDate
) : ICommand<DelegationId>;

public record RevokeDelegationCommand(
    DelegationId DelegationId,
    EmployeeId RevokedById
) : ICommand;
```

### Queries (F-002)

```csharp
// PM approval queue — BR-018: only requests from own project members
public record GetProjectApprovalQueueQuery(
    EmployeeId ProjectManagerId,
    int Page = 1, int PageSize = 20
) : IQuery<PagedResult<ApprovalQueueItemDto>>;

// DM approval queue — includes project-approved + project-rejected appeals
public record GetDepartmentApprovalQueueQuery(
    EmployeeId DepartmentManagerId,
    int Page = 1, int PageSize = 20
) : IQuery<PagedResult<ApprovalQueueItemDto>>;

// Active delegation for a given approver (at most one per scope)
public record GetActiveDelegationQuery(
    EmployeeId ApproverId,
    DelegationScope Scope
) : IQuery<DelegationDto?>;
```

---

## Ubiquitous Language

| Term | Definition | Context |
|------|------------|---------|
| **Approval Workflow** | The process that governs how a vacation request moves through two approval levels | ApprovalWorkflow |
| **Level 1 (Project)** | The first approval stage performed by the Project Manager | ApprovalWorkflow |
| **Level 2 (Department)** | The final approval stage performed by the Department Manager | ApprovalWorkflow |
| **Approval Step** | An individual approval or rejection action at one level | ApprovalWorkflow |
| **Delegation** | Temporary or permanent transfer of approval authority to a designated backup | ApprovalWorkflow |
| **Delegate** | The employee who receives delegated approval authority | ApprovalWorkflow |
| **Delegator** | The approver granting authority to a delegate | ApprovalWorkflow |
| **Escalation** | Automatic alert to DM when a request remains pending beyond threshold | ApprovalWorkflow |
| **Reminder** | Day-3 notification to PM that a request is still pending | ApprovalWorkflow |
| **Direct Escalation** | Day-5 escalation enabling DM to bypass PM and act directly | ApprovalWorkflow |
| **Appeal** | Employee action to bring a PM-rejected request to the DM for reconsideration | ApprovalWorkflow |
| **Override** | DM approval of a PM-rejected request, superseding the PM decision | ApprovalWorkflow |

---

## Integration with Other Bounded Contexts

| Bounded Context | Direction | Mechanism | Data |
|-----------------|-----------|-----------|------|
| **VacationManagement (F-001)** | Bidirectional | CQRS dispatcher | Read RequestId; call `TransitionTo()` on VacationRequest |
| **Notifications (F-006)** | Outbound (events) | Service Bus | Approval events trigger email/Teams to employee and approvers |
| **CapacityManagement (F-003)** | Outbound (events) | Service Bus | `VacationRequestApprovedFinal` triggers cache invalidation |
| **Reporting (F-007)** | Outbound (data) | Read model (Dapper) | Approval time metrics consumed by reports |
