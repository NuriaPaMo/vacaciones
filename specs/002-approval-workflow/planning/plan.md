# Technical Plan — F-002: Approval Workflow

## Metadata

| Property          | Value                                              |
| ----------------- | -------------------------------------------------- |
| Feature           | F-002 — Approval Workflow                          |
| Scenario          | Fullstack (backend + frontend + cloud-platform)    |
| Bounded Context   | ApprovalWorkflow (Core Domain)                     |
| Bolt              | Bolt 2 — Week 7–8                                  |
| Issue             | gh#3                                               |
| Author            | Bolt Plan Agent                                    |
| Created           | 2026-08-07                                         |
| Status            | Draft                                              |
| Dependencies      | F-001 complete (VacationRequest, Employee entities exist) |

---

## Executive Summary

F-002 implements the **two-level approval workflow** (Project Manager → Department Manager),
delegation of authority, and automated escalation. It extends the `VacationRequest` state machine
defined in F-001 by introducing the `ApprovalWorkflow` aggregate and `Delegation` aggregate.
The escalation background service runs every 30 minutes, checking pending approvals.

---

## Architecture Context

| Concern | Decision |
|---------|----------|
| Module | `src/Modules/ApprovalWorkflow/` |
| Pattern | Simple CQRS — `ApproveAtProjectLevelCommand`, `RejectAtProjectLevelCommand`, etc. |
| Auth | `RequireProjectManager`, `RequireDepartmentManager` policies |
| Escalation | `.NET BackgroundService` — polls every 30 minutes; uses Redis distributed lock |
| Events | Service Bus: `vacation.approved.project`, `vacation.approved.final`, `vacation.rejected.*`, `approval.escalated` |
| State transition | Calls `VacationRequest.TransitionTo()` via F-001 repository in same UoW |

---

## Bolt Breakdown

| Bolt | Scope | Focus | Duration |
|------|-------|-------|----------|
| **2A** | Backend | ApprovalWorkflow aggregate + Delegation + CQRS commands | 3 days |
| **2B** | Backend + Frontend | Escalation service + PM/DM approval queue UI | 4 days |

---

## Bolt 2A — Approval Aggregates & Commands

### Module Structure

```
src/Modules/ApprovalWorkflow/
  ├── Domain/
  │   ├── ApprovalWorkflow.cs          ← Aggregate Root
  │   ├── ApprovalStep.cs              ← Child Entity
  │   ├── Delegation.cs                ← Aggregate Root
  │   ├── EscalationEvent.cs           ← Entity
  │   └── ValueObjects/
  │       ├── ApprovalWorkflowId.cs
  │       ├── DelegationId.cs
  │       ├── ApprovalLevel.cs         ← enum: Project=1, Department=2
  │       ├── ApprovalDecision.cs      ← enum: Approved, Rejected
  │       ├── DelegationScope.cs
  │       └── EscalationThreshold.cs  ← VO: ReminderAfterDays, EscalationAfterDays
  ├── Application/
  │   ├── Commands/
  │   │   ├── ApproveAtProjectLevel/
  │   │   ├── RejectAtProjectLevel/
  │   │   ├── ApproveAtDepartmentLevel/
  │   │   ├── RejectAtDepartmentLevel/
  │   │   ├── AppealProjectRejection/
  │   │   ├── CreateDelegation/
  │   │   └── RevokeDelegation/
  │   └── Queries/
  │       ├── GetProjectApprovalQueue/
  │       └── GetDepartmentApprovalQueue/
  ├── Infrastructure/
  │   ├── Persistence/
  │   │   ├── ApprovalWorkflowRepository.cs
  │   │   ├── DelegationRepository.cs
  │   │   └── Configurations/
  │   └── BackgroundServices/
  │       └── EscalationBackgroundService.cs
  └── Api/
      ├── ApprovalEndpoints.cs
      └── DelegationEndpoints.cs
```

### Implementation Checklist — Bolt 2A

- [ ] `ApprovalWorkflow` aggregate — INV-101–106; all domain methods
- [ ] `ApprovalStep` child entity — `IsDelegate` flag for delegated actions (BR-029)
- [ ] `Delegation` aggregate — INV-110–113; `IsEffectiveOn(date)`, `Revoke()` method
- [ ] `EscalationThreshold` value object — configurable from `SystemConfiguration` (F-007)
- [ ] `ApprovalWorkflow.ApproveAtProjectLevel()` — validates PM authority (BR-018); handles self-approval for PM-who-is-DM (BR-019a)
- [ ] `ApprovalWorkflow.ApproveAtDepartmentLevel()` — final approval; sets `CompletedAt`
- [ ] `ApprovalWorkflow.RejectAtProjectLevel()` — rejection NOT final (BR-016); reason ≥ 10 chars
- [ ] `ApprovalWorkflow.RejectAtDepartmentLevel()` — final rejection; overrides project approval
- [ ] `ApprovalWorkflow.EscalateToDepartment()` — records EscalationEvent; bypasses PM on Day 5
- [ ] Circular delegation check in `CreateDelegationHandler` (BR-027)
- [ ] One-active-delegation-per-approver enforcement (BR-028)
- [ ] EF Core migration: `M003_CreateApprovalWorkflowTables`
- [ ] `ApprovalWorkflowRepository`: `GetByRequestIdAsync`, `SaveAsync`
- [ ] `DelegationRepository`: `GetActiveDelegationAsync(delegatorId, scope)`, `SaveAsync`
- [ ] Publish domain events to Service Bus on every terminal transition

---

## Bolt 2B — Escalation Service & Approval Queue UI

### Backend — Escalation BackgroundService

```csharp
// Runs every 30 minutes (configurable)
public class EscalationBackgroundService : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            using var distributedLock = await _lockProvider.AcquireAsync("escalation-job");
            if (distributedLock.IsAcquired)
            {
                await ProcessPendingEscalationsAsync(stoppingToken);
            }
            await Task.Delay(TimeSpan.FromMinutes(30), stoppingToken);
        }
    }
}
```

**Escalation logic per pending workflow**

1. Query: `SELECT * FROM APPROVAL_WORKFLOWS WHERE CurrentLevel = 1 AND CompletedAt IS NULL`
2. For each: calculate business days since `CreatedAt`
3. If days ≥ 3 (reminder threshold): raise `EscalationTriggered(Reminder)` → Service Bus
4. If days ≥ 5 (escalation threshold): raise `EscalationTriggered(DirectEscalation)` → Service Bus + move to DM queue
5. Mark `EscalationEvent` as resolved when workflow completes

### Backend — API Endpoints

| Method | Route | Handler | Auth Policy |
|--------|-------|---------|-------------|
| `POST` | `/api/vacation-requests/{id}/approve/project` | `ApproveAtProjectLevelHandler` | `RequireProjectManager` |
| `POST` | `/api/vacation-requests/{id}/reject/project` | `RejectAtProjectLevelHandler` | `RequireProjectManager` |
| `POST` | `/api/vacation-requests/{id}/approve/department` | `ApproveAtDepartmentLevelHandler` | `RequireDepartmentManager` |
| `POST` | `/api/vacation-requests/{id}/reject/department` | `RejectAtDepartmentLevelHandler` | `RequireDepartmentManager` |
| `POST` | `/api/vacation-requests/{id}/appeal` | `AppealProjectRejectionHandler` | `RequireEmployee` |
| `GET` | `/api/approval-queue/project` | `GetProjectApprovalQueueHandler` | `RequireProjectManager` |
| `GET` | `/api/approval-queue/department` | `GetDepartmentApprovalQueueHandler` | `RequireDepartmentManager` |
| `POST` | `/api/delegations` | `CreateDelegationHandler` | `RequireProjectManager` OR `RequireDepartmentManager` |
| `DELETE` | `/api/delegations/{id}` | `RevokeDelegationHandler` | `RequireProjectManager` OR `RequireDepartmentManager` |
| `GET` | `/api/delegations/active` | `GetActiveDelegationHandler` | `RequireProjectManager` OR `RequireDepartmentManager` |

**Approval queue item DTO**

```csharp
record ApprovalQueueItemDto(
    Guid RequestId,
    string EmployeeName,
    string ProjectName,
    DateOnly StartDate,
    DateOnly EndDate,
    int TotalDays,
    DateTime SubmittedAt,
    string CurrentStatus,
    decimal? CapacityImpactPercent,   // from F-003 read model
    bool IsEscalated
);
```

### Frontend Tasks — Vue 3 SPA

```
src/frontend/src/modules/approval/
  ├── views/
  │   ├── ProjectApprovalQueueView.vue   ← US-004
  │   ├── DeptApprovalQueueView.vue      ← US-005
  │   └── DelegationManagementView.vue   ← US-006
  ├── components/
  │   ├── ApprovalQueueTable.vue
  │   ├── ApprovalActionPanel.vue        ← Approve / Reject with reason
  │   ├── RejectReasonModal.vue          ← min 10 chars validation
  │   ├── CapacityImpactBadge.vue        ← shows % if >70% (AC-004.6, AC-005.4)
  │   ├── DelegationForm.vue
  │   └── DelegationStatusCard.vue
  ├── stores/
  │   ├── approvalQueueStore.ts
  │   └── delegationStore.ts
  └── api/
      └── approvalApi.ts
```

**Implementation checklist — Bolt 2B frontend**

- [ ] `approvalQueueStore` — `fetchPMQueue`, `fetchDMQueue`, `approve`, `reject` actions
- [ ] `ProjectApprovalQueueView` — table with employee, dates, days, submission date, capacity impact (AC-004.6)
- [ ] `DeptApprovalQueueView` — includes project-approved AND project-rejected appeals (AC-005.3)
- [ ] `RejectReasonModal` — textarea; submit disabled until ≥ 10 chars (BR-017)
- [ ] `CapacityImpactBadge` — red warning when the period is over-requested (AC-005.4)
- [ ] `DelegationForm` — date range picker + delegate selector; shows active delegation (AC-006.1)
- [ ] Route guards: `requirePM` / `requireDM` middleware
- [ ] Deep-link navigation from email action links (AC-020.1) — route accepts `?requestId=xxx`

---

## Test Strategy

### Backend

| Type | Key Scenarios |
|------|---------------|
| Domain Unit | `ApprovalWorkflow` state transitions — all allowed + all forbidden |
| Domain Unit | `Delegation.IsEffectiveOn()` — within range, expired, permanent |
| Domain Unit | Circular delegation check (A→B and B→A simultaneously) |
| Domain Unit | Self-approval: PM who is DM processes both levels in one step |
| Application Unit | `ApproveAtProjectLevelHandler` — PM not in project → 403 |
| Application Unit | `CreateDelegationHandler` — duplicate active delegation → 409 |
| Integration | Full approval flow: submit → PM approve → DM approve → status = Approved |
| Integration | Escalation service: pending workflow → Day 3 reminder → Day 5 DM alert |
| BDD | AC-004.1 `@smoke` — PM approves, status → PendingDepartmentApproval |
| BDD | AC-004.2 `@smoke` — PM rejects with reason |
| BDD | AC-006.1 `@smoke` — delegation created; delegate sees requests |
| BDD | AC-006.3 `@smoke` — delegated action recorded with both identities |

### Frontend

| Type | Key Scenarios |
|------|---------------|
| Store | `reject` — validates reason length before API call |
| Component | `RejectReasonModal` — submit disabled until ≥ 10 chars |
| E2E | `@smoke` — PM views queue and approves a request |
| E2E | `@smoke` — PM rejects with mandatory reason |
| E2E | DM views queue including appealed requests |

---

## Quality Gates

Same as F-001. Both Bolts (2A and 2B) must pass all gates before merge.

| Gate | Threshold |
|------|-----------|
| Line coverage | ≥ 80% |
| Linting | 0 errors |
| Architecture | All NetArchTest rules pass |
| BDD `@smoke` | 100% |
| Playwright `@smoke` | 100% |
| API P95 latency | < 300 ms |

---

## Risks & Mitigations

| Risk | Prob | Impact | Mitigation |
|------|------|--------|------------|
| State machine complexity — PM-who-is-DM self-approval edge case | High | High | Dedicated unit test covering all BR-019a scenarios |
| Escalation job double-fires on multi-instance deployment | Medium | Medium | Redis distributed lock (`IDistributedLock`); idempotent event IDs |
| Circular delegation not detected efficiently | Low | High | DB constraint + application-level check before insert |
| Appeal path from `RejectedAtProjectLevel` unclear UX | Medium | Medium | Wire UI with explicit "Appeal to DM" button; clear status label |
| Delegate loses access mid-approval if delegation expires during workflow | Low | Medium | Record delegation state snapshot in `ApprovalStep.IsDelegate` |

---

## Dependencies

| Dependency | Type | Status |
|-----------|------|--------|
| F-001 complete — `VacationRequest` entity + `TransitionTo()` method | Hard | Blocks Bolt 2A start |
| Service Bus topics: `vacation.approved.*`, `vacation.rejected.*`, `approval.escalated` | Hard | Platform Engineer provisions in Phase 4 |
| F-003 capacity read model | Soft | `CapacityImpactPercent` shows 0 until F-003 is live |
| F-006 notifications | Soft | Approval events published; F-006 consumes them |
