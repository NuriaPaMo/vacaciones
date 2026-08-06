# Feature: Approval Workflow

## Metadata

| Property   | Value                                          |
| ---------- | ---------------------------------------------- |
| Feature ID | F-002                                          |
| Issue      | gh#3                                           |
| Author     | Bolt Feature Agent                             |
| Created    | 2026-08-06                                     |
| Status     | Draft                                          |
| Priority   | P1                                             |
| Epic       | Vacation Management & Approval System          |
| Scenario   | fullstack (backend + frontend + cloud-platform) |
| Bolt       | Bolt 2 (Week 7-8)                              |

---

## Business Context

### Problem Statement

Vacation approvals currently rely on email chains between project managers and department managers,
resulting in lost requests, inconsistent workflows, and average approval times of 5-7 days. There
is no formal delegation mechanism, and escalation for overdue approvals does not exist.

### Business Value

- Reduce approval cycle time from 5-7 days to < 48 hours
- Enforce consistent two-level approval (project → department)
- Enable delegation so vacations don't block approvals
- Automatic escalation prevents requests from being forgotten
- Complete audit trail for compliance

### Target Users

| Persona            | Description                       | Goals                                               |
| ------------------ | --------------------------------- | --------------------------------------------------- |
| Project Manager    | Approves at project level         | Quick approve/reject, delegate when unavailable     |
| Department Manager | Final approval authority          | Department-wide view, override capability           |
| Employee           | Request submitter                 | Fast approval turnaround                            |

---

## User Stories

### US-004: Project-Level Approval

**As a** project manager
**I want** to approve or reject vacation requests from my team members
**So that** I can ensure adequate project coverage before escalating to department level

**Priority**: P1
**Effort**: L
**Dependencies**: F-001 (VacationRequest entity)

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-004.1  | Given a pending request from a team member, when the PM clicks "Approve", then the request advances to department-level approval | Functional   | @smoke |
| AC-004.2  | Given a pending request, when the PM clicks "Reject" and provides a reason, then the request status changes to "Rejected at Project Level" (employee can appeal to DM) | Functional   | @smoke |
| AC-004.3  | Given a rejection, when no reason is provided, then the system prevents the action with a validation error | Functional   | —      |
| AC-004.4  | Given an authenticated PM, when they view their approval queue, then they see only requests from employees assigned to their projects | Functional   | @smoke |
| AC-004.5  | Given a request approved at project level, when the department manager has not yet acted, then the request status shows "Pending Department Approval" | Functional   | —      |
| AC-004.6  | Given the approval queue, when displayed, then it shows: employee name, dates, total days, submission date, and capacity impact | Functional   | —      |

#### Business Rules

- BR-015: Project approval is Level 1 in the approval chain
- BR-016: Rejection at project level is NOT final; employee can appeal to the DM who may override (CL-006 resolved)
- BR-017: Rejection requires a mandatory reason (min 10 characters)
- BR-018: A PM can only see/approve requests from employees in their projects
- BR-019: If an employee belongs to multiple projects, the primary project PM approves
- BR-019a: A PM who is also a DM can self-approve at both levels (CL-005 resolved)
- BR-019b: A DM can approve their own vacation request (self-approval allowed) (CL-005 resolved)
- BR-019c: Single PM approves per project; single DM approves per department (CL-008 resolved)

---

### US-005: Department-Level Approval

**As a** department manager
**I want** to provide final approval on vacation requests that have passed project-level review
**So that** I can ensure department-wide coverage compliance

**Priority**: P1
**Effort**: L
**Dependencies**: US-004

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-005.1  | Given a request approved at project level, when the DM clicks "Approve", then the request status changes to "Approved" (final) | Functional   | @smoke |
| AC-005.2  | Given a request, when the DM clicks "Reject" with a reason, then the request status changes to "Rejected" (overriding project approval) | Functional   | @smoke |
| AC-005.3  | Given an authenticated DM, when they view their approval queue, then they see all project-approved requests AND project-rejected appeals from their department | Functional   | —      |
| AC-005.4  | Given the DM approval queue, when a request is in an over-requested period (>70%), then a visual warning is displayed with suggested alternative dates | Functional   | —      |
| AC-005.5  | Given a final approval, when the request becomes "Approved", then the capacity calculation for the affected period is updated | Functional   | —      |

#### Business Rules

- BR-020: Department approval is Level 2 (final) in the approval chain
- BR-021: Both project AND department approval required before marking as "Approved"
- BR-022: DM rejection overrides project-level approval
- BR-023: DM can view all requests regardless of project
- BR-024: Only "Approved" (by both levels) requests are eligible for ServiceNow export

---

### US-006: Approval Delegation

**As an** approver (PM or DM)
**I want** to delegate my approval authority to another person
**So that** vacation requests are not blocked when I am unavailable

**Priority**: P1
**Effort**: M
**Dependencies**: US-004, US-005

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-006.1  | Given an approver, when they configure a delegation with start/end dates and delegate user, then the delegate receives approval authority for that period | Functional   | @smoke |
| AC-006.2  | Given an active delegation, when a new request arrives, then both the original approver and the delegate can see and act on it | Functional   | —      |
| AC-006.3  | Given a delegated approval, when the delegate approves/rejects, then the audit trail records both the delegate and the original approver | Functional   | @smoke |
| AC-006.4  | Given a delegation, when the end date passes, then the delegation automatically expires and the delegate loses authority | Functional   | —      |
| AC-006.5  | Given an approver, when they revoke a delegation before the end date, then the delegation is immediately deactivated | Functional   | —      |
| AC-006.6  | Given a delegation, when created without an end date, then it remains active until explicitly revoked (permanent delegation) | Functional   | —      |

#### Business Rules

- BR-025: Delegation can be temporary (date range) or permanent (until revoked)
- BR-026: Delegates must be designated backup approvers from the same project (PM) or department (DM); cannot delegate to any employee (CL-009 resolved)
- BR-027: Circular delegation is not allowed (A → B → A)
- BR-028: Maximum one active delegation per approver at any time
- BR-029: Delegated actions are fully audited with both delegate and delegator identity
- BR-029a: When a PM submits their own vacation request, the system must auto-trigger delegation to a designated backup (CL-009 resolved)
- BR-029b: Delegation conditions (e.g., max days) are not supported; delegation covers all requests (CL-009 resolved)

---

### US-007: Approval Escalation

**As a** department manager
**I want** the system to alert me when requests have been pending too long
**So that** no vacation request is forgotten or indefinitely delayed

**Priority**: P2
**Effort**: M
**Dependencies**: US-004, US-005

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-007.1  | Given a request pending at project level for more than X days (configurable, default 3), then the system sends a reminder to the PM | Functional   | @smoke |
| AC-007.2  | Given a request pending at project level for more than Y days (configurable, default 5), then the system escalates by alerting the DM | Functional   | —      |
| AC-007.3  | Given an escalation, when the DM is alerted, then the DM can directly approve/reject bypassing the PM level | Functional   | —      |
| AC-007.4  | Given escalation thresholds, when an administrator changes them, then new values apply to all future pending requests | Functional   | —      |
| AC-007.5  | Given an escalation event, when triggered, then the audit trail records the escalation with timestamp and reason | Functional   | —      |

#### Business Rules

- BR-030: Default escalation thresholds: reminder at 3 days, escalation at 5 days
- BR-031: Escalation thresholds are configurable per department (by admin)
- BR-032: Escalation does NOT revoke PM authority; both PM and DM can act on escalated requests (CL-007 resolved)
- BR-033: Escalation does not auto-approve; it alerts and enables action
- BR-034: Business days only count for escalation calculations

---

## Non-Functional Requirements

### Performance

| Metric               | Target     | Measurement                    |
| -------------------- | ---------- | ------------------------------ |
| Approve/Reject API   | < 300 ms   | API response P95               |
| Approval Queue Load  | < 2 s      | Page load with 50+ requests    |
| Escalation Check     | < 5 min    | Background job cycle time      |

### Security

- [x] Authentication required (Entra ID)
- [x] Authorization rules defined:
  - PM: approve/reject only for their project members
  - DM: approve/reject for entire department
  - Delegates: same permissions as delegator (scoped)
- [x] Data encryption at rest and in transit
- [x] Audit logging for all approval actions

### Scalability

- Expected concurrent approvers: 60 (50 PMs + 10 DMs)
- Peak approval load: 200 requests/day (summer season)
- Escalation job processes all pending requests in < 5 minutes

### Availability

- Target uptime: 99.5%
- Escalation background job: runs every 30 minutes

---

## Data Requirements

### New Entities

| Entity              | Description                              | Key Fields                                                        |
| ------------------- | ---------------------------------------- | ----------------------------------------------------------------- |
| ApprovalStep        | Individual approval action               | Id, RequestId, Level (Project/Department), ApproverId, Status, ActedAt, Reason |
| Delegation          | Approval authority delegation            | Id, DelegatorId, DelegateId, Scope, StartDate, EndDate, IsActive  |
| EscalationEvent     | Record of escalation triggers            | Id, RequestId, Level, TriggeredAt, Reason, ResolvedAt             |

### Modified Entities

| Entity          | Changes                         | Impact                          |
| --------------- | ------------------------------- | ------------------------------- |
| VacationRequest | Add: CurrentApprovalLevel field | Tracks where in workflow it is  |

---

## Integration Points

| System       | Direction | Protocol              | Purpose                              |
| ------------ | --------- | --------------------- | ------------------------------------ |
| Entra ID     | Inbound   | OAuth 2.0 / JWT       | Approver authentication              |
| Service Bus  | Outbound  | Azure Service Bus     | Escalation check trigger (scheduled) |
| Frontend     | Outbound  | REST API              | Approval queue and actions           |

---

## Out of Scope

- Notification delivery mechanism (F-006 handles email/Teams)
- Calendar visualization of capacity impact (F-003)
- ServiceNow export of approved requests (F-005)
- Approval analytics and reporting (F-007)

## Dependencies

- F-001: VacationRequest entity and Employee entity must exist
- Entra ID roles/claims for PM and DM identification
- Azure Service Bus for scheduled escalation processing

## Resolved Questions

- ~~Q-004~~: **Resolved (CL-006)** — Yes, DM can override a PM rejection. Employee can appeal project-level rejections to DM.
- ~~Q-005~~: **Resolved (CL-005)** — Yes, PM/DM can self-approve at both levels.
- ~~Q-006~~: **Resolved (CL-007)** — Escalation does NOT revoke PM authority. Both PM and DM can act after escalation. Priority conflict resolution deferred (not required this phase).

## Open Questions

_None — all questions resolved._

---

## Next Steps

> Spec generated in `specs/002-approval-workflow/`. Scenario: **fullstack**.
>
> Recommended next:
>
> 1. Invoke `bolt-mockup` (mode: generate) for approval queue UI and delegation management.
> 2. Then → `bolt-plan` + `bolt-gherkin` (in parallel).
