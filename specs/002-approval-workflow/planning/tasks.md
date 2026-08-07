# Task List — F-002: Approval Workflow

## Metadata

| Property       | Value                                               |
| -------------- | --------------------------------------------------- |
| Feature        | F-002 — Approval Workflow                           |
| Scenario       | Fullstack (backend + frontend + cloud-platform)     |
| Source plan    | `planning/plan.md`                                  |
| Gherkin source | `tests/project-level-approval.feature` · `tests/department-level-approval.feature` · `tests/approval-delegation.feature` · `tests/approval-escalation.feature` |
| Steps stub     | `tests/ApprovalWorkflow.ReqnrollTests/StepDefinitions/ApprovalWorkflowSteps.cs` |
| Created        | 2026-08-07                                          |
| Status         | Ready for execution                                 |

---

## Reconciliation plan ↔ Gherkin

### Coverage

| Metric | Count |
|--------|-------|
| Endpoints planned | 10 |
| Endpoints with BDD coverage | 10 |
| `@smoke` scenarios | 10 (3 PM + 2 DM + 2 delegation + 1 escalation + 2 queue) |
| `@smoke` with planned implementation | 10 |
| Gaps | 1 (minor) |

### Gaps detected

- **Minor gap:** `approval-escalation.feature` scenario "DM can directly approve bypassing PM" (AC-007.3) is covered by `EscalationBackgroundService` moving request to DM queue, but the plan does not have an explicit task for the `AppealProjectRejectionCommand` being triggered automatically on DirectEscalation. → **T021 added** to explicitly wire escalation → DM queue transition.
- Step definitions stub requires implementation → **T037** added in Bolt 2C.

---

## Auto-Split Log

| Original Bolt | Decision | Reason |
|--------------|----------|--------|
| Bolt 2A (aggregates + commands) | **Split → Bolt 2A + Bolt 2B** | 13 tasks > 8-task limit |
| Bolt 2B (escalation + frontend) | Renamed → **Bolt 2C**; kept as single (9 tasks, 4.5L < 5L) | Weight within limit |

---

## User Story → Bolt Map

| User Story | Priority | Bolt |
|-----------|---------|------|
| US-004 Project-Level Approval | P1 | Bolt 2A + 2B + 2C |
| US-005 Department-Level Approval | P1 | Bolt 2A + 2B + 2C |
| US-006 Approval Delegation | P1 | Bolt 2A + 2B |
| US-007 Approval Escalation | P2 | Bolt 2C |

---

## Bolt 2A — ApprovalWorkflow Domain Layer

**Goal:** Pure domain — aggregates, value objects, domain events.
**Duration:** 2–3 days · **Weight:** 4.25L equivalent

### Domain

- [x] T001 [S] Create `src/Modules/ApprovalWorkflow/` folder structure
- [x] T002 [M] [US-004][US-005] Implement `ApprovalWorkflowId`, `DelegationId`, `ApprovalLevel`, `ApprovalDecision`, `DelegationScope`, `EscalationType` value objects
- [x] T003 [L] [US-004][US-005] Implement `ApprovalWorkflow` aggregate root: `ApproveAtProjectLevel()`, `RejectAtProjectLevel()`, `ApproveAtDepartmentLevel()`, `RejectAtDepartmentLevel()`, `EscalateToDepartment()`, `IsCompleted()` — all 6 invariants (INV-101–106) including self-approval (BR-019a)
- [x] T004 [M] [US-004][US-005] Implement `ApprovalStep` child entity (`IsDelegate` flag; `OriginalApproverId` when acting as delegate)
- [x] T005 [M] [US-006] Implement `Delegation` aggregate root: `IsEffectiveOn(date)`, `Revoke()` — invariants INV-110–113 (circular check, one-active-per-scope)
- [x] T006 [S] [US-007] Implement `EscalationEvent` entity + `EscalationThreshold` value object (default: reminder=3d, escalation=5d)
- [x] T007 [S] Implement domain events: `VacationRequestApprovedAtProjectLevel`, `VacationRequestApprovedFinal`, `VacationRequestRejectedAtProjectLevel`, `VacationRequestRejectedFinal`, `ApprovalEscalationTriggered`

### Tests

- [x] T008 [M] [US-004][US-005] xUnit: `ApprovalWorkflow` state machine — all 11 allowed transitions; all forbidden transitions throw `DomainException`; self-approval PM-who-is-DM (BR-019a)
- [x] T009 [M] [US-006] xUnit: `Delegation` invariants — circular delegation check; max-one-active enforcement; `IsEffectiveOn` boundary values (start, end, null = permanent)

### Quality Gates — Bolt 2A

- [x] T010-QG `dotnet build --warnaserror` → 0 warnings
- [x] T011-QG `dotnet test --filter Category=Unit` → 100% pass
- [x] T012-QG Coverlet line coverage (Domain project) → ≥ 80%
- [x] T013-QG Coverlet branch coverage → ≥ 75%
- [ ] T014-QG `dotnet stryker --project ApprovalWorkflow.Domain.csproj` → ≥ 70%

---

## Bolt 2B — Persistence, Repositories & CQRS Commands

**Goal:** EF context, migrations, repositories, all 7 CQRS commands.
**Duration:** 2–3 days · **Weight:** 4.0L equivalent

### Persistence

- [ ] T015 [M] EF Core configurations for `ApprovalWorkflow`, `ApprovalStep`, `Delegation`, `EscalationEvent`; unique constraint on `(RequestId)` for workflow; `IX_DEL_DelegatorId_Active` + `IX_DEL_DelegateId_Active` indexes
- [ ] T016 [M] [P] Migration `M003_CreateApprovalWorkflowTables`; verify applied to dev

### Repositories

- [ ] T017 [M] `ApprovalWorkflowRepository`: `GetByRequestIdAsync`, `SaveAsync`
- [ ] T018 [M] `DelegationRepository`: `GetActiveDelegationAsync(delegatorId, scope)`, `SaveAsync`, `GetAllActiveAsync`

### Application — Commands

- [ ] T019 [M] [US-004] `ApproveAtProjectLevelCommand` + handler (validates PM authority via `BR-018`; resolves delegate identity when `DelegationId` provided)
- [ ] T020 [M] [US-004] `RejectAtProjectLevelCommand` + handler (reason ≥ 10 chars; BR-017)
- [ ] T021 [M] [US-005] `ApproveAtDepartmentLevelCommand` + handler (final approval; updates capacity via event)
- [ ] T022 [M] [US-005] `RejectAtDepartmentLevelCommand` + handler (final rejection; overrides PM decision)
- [ ] T023 [M] [US-005] `AppealProjectRejectionCommand` + handler (employee moves `RejectedAtProjectLevel` → DM queue; BR-016); also used by DirectEscalation flow (gap fix)
- [ ] T024 [M] [US-006] `CreateDelegationCommand` + handler (circular check; one-active-per-scope guard; BR-027–028)
- [ ] T025 [M] [US-006] `RevokeDelegationCommand` + handler

### Tests

- [ ] T026 [M] [P] xUnit: `ApproveAtProjectLevelCommand` handler — PM not in project → 403; delegate resolution; self-approval path
- [ ] T027 [M] [P] xUnit: `CreateDelegationCommand` — duplicate active delegation → 409; circular delegation rejected

### Quality Gates — Bolt 2B

- [ ] T028-QG `dotnet build --warnaserror` → 0 warnings
- [ ] T029-QG `dotnet test` → 100% pass
- [ ] T030-QG Coverlet line + branch coverage (Infrastructure + Application) → ≥ 80% / 75%
- [ ] T031-QG `dotnet stryker --project ApprovalWorkflow.Application.csproj` → ≥ 70%
- [ ] T032-QG Migrations applied to dev → `/health/ready` 200

---

## Bolt 2C — Queries, Escalation Service, Vue SPA & Step Definitions

**Goal:** 3 queries, 2 queue API endpoints, escalation BackgroundService, Vue approval/delegation UI.
**Duration:** 3 days · **Weight:** 4.5L equivalent

### Application — Queries

- [ ] T033 [M] [US-004] `GetProjectApprovalQueueQuery` + handler (Dapper: filters to own project; includes capacity impact; BR-018)
- [ ] T034 [M] [US-005] `GetDepartmentApprovalQueueQuery` + handler (Dapper: includes project-approved + appealed; BR-023)
- [ ] T035 [S] `GetActiveDelegationQuery` + handler

### Infrastructure — Escalation

- [ ] T036 [L] [US-007] `EscalationBackgroundService`: 30-min poll loop; Redis distributed lock (`escalation-running`); business-day calculation; Reminder at day 3 → publishes event; DirectEscalation at day 5 → triggers `AppealProjectRejectionCommand` to DM queue; resolves on workflow completion

### API

- [ ] T037 [M] Approval endpoints (10 routes: approve/reject L1+L2, appeal, delegation CRUD, queue GET × 2) with `RequireProjectManager` / `RequireDepartmentManager` policies; `RequireEmployee` for appeal

### Frontend

- [ ] T038 [M] [US-004] Vue: `approvalQueueStore.ts` + `ProjectApprovalQueueView.vue` + `ApprovalQueueTable.vue` (employee, dates, days, capacity badge, escalation icon)
- [ ] T039 [M] [US-005] Vue: `DeptApprovalQueueView.vue` + `RejectReasonModal.vue` (min-10-char validation; submit disabled until valid; BR-016 appeal info banner)
- [ ] T040 [M] [US-006] Vue: `DelegationManagementView.vue` + `DelegationForm.vue` + `DelegationStatusCard.vue`

### BDD Step Definitions

- [ ] T041 [M] [P] Implement `ApprovalWorkflowSteps.cs` body methods for all 4 `.feature` files

### Tests

- [ ] T042 [M] [P] xUnit + Testcontainers: full approval flow (submit → PM approve → DM approve → status = Approved)
- [ ] T043 [M] [P] xUnit + Testcontainers: escalation — pending request day 3 → Reminder; day 5 → DirectEscalation + DM queue
- [ ] T044 [M] Vitest: `RejectReasonModal` (submit disabled until ≥ 10 chars); `approvalQueueStore` (approve/reject actions)

### Quality Gates — Bolt 2C

- [ ] T045-QG `dotnet format` / `eslint` → 0 errors
- [ ] T046-QG `dotnet test` + `npm test` → 100% pass
- [ ] T047-QG Coverlet BE ≥ 80% line / 75% branch; Vitest FE ≥ 80%
- [ ] T048-QG-E2E Playwright `@smoke`: `approval-workflow.spec.ts` → 0 failures (PM approve, PM reject, DM approve, delegation create)
- [ ] T049-QG NetArchTest → all rules pass
- [ ] T050-QG k6 smoke: `POST /api/vacation-requests/{id}/approve/project` P95 < 300 ms
- [ ] T051-QG SAST scan → 0 Critical
