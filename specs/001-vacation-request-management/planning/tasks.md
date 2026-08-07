# Task List — F-001: Vacation Request Management

## Metadata

| Property       | Value                                               |
| -------------- | --------------------------------------------------- |
| Feature        | F-001 — Vacation Request Management                 |
| Scenario       | Fullstack (backend + frontend + cloud-platform)     |
| Source plan    | `planning/plan.md`                                  |
| Gherkin source | `tests/submit-vacation-request.feature` · `tests/track-vacation-request.feature` · `tests/cancel-vacation-request.feature` |
| Steps stub     | `tests/VacationManagement.ReqnrollTests/StepDefinitions/VacationRequestSteps.cs` |
| Created        | 2026-08-07                                          |
| Status         | Ready for execution                                 |

---

## Reconciliation plan ↔ Gherkin

### Coverage

| Metric | Count |
|--------|-------|
| Endpoints planned | 4 (POST, GET list, GET detail, DELETE) |
| Endpoints with BDD coverage | 4 |
| `@smoke` scenarios | 8 (3 submit + 2 track + 2 cancel + 1 calendar UI) |
| `@smoke` with planned implementation | 8 |
| Gaps | 0 |

### Gaps detected

- **No gaps.** All `@smoke` scenarios in the three `.feature` files map to tasks in this list.
- Step definitions stub at `VacationRequestSteps.cs` requires implementation task → added as **T025** in Bolt 1C.
- `Scenario Outline: Minimum advance notice` (submit.feature) maps to `BR-002` — covered by `T007` (CalculateBusinessDays unit tests include boundary dates).

---

## Auto-Split Log

| Original Bolt | Decision | Reason |
|--------------|----------|--------|
| Bolt 1A (domain + persistence) | **Split → Bolt 1A + Bolt 1B** | 13 tasks > 8-task limit |
| Bolt 1B (API + frontend) | Renamed → **Bolt 1C**; kept as single (10 tasks, 4.5L < 5L limit) | Weight within limit; tasks tightly coupled |

---

## User Story → Bolt Map

| User Story | Priority | Bolt |
|-----------|---------|------|
| US-001 Submit Vacation Request | P1 | Bolt 1A + 1B + 1C |
| US-002 Track Request Status | P1 | Bolt 1C |
| US-003 Cancel Vacation Request | P1 | Bolt 1C |

---

## Bolt 1A — VacationManagement Domain Layer

**Goal:** Pure domain model — aggregate, value objects, domain events, unit tests.
**Duration:** 2–3 days · **Weight:** 4.0L equivalent

### Domain

- [ ] T001 [S] Create `src/Modules/VacationManagement/` folder structure (Domain / Application / Infrastructure / Api sub-trees)
- [ ] T002 [M] [US-001] Implement `DateRange` value object with `CalculateBusinessDays()` (Mon–Fri, inclusive) — `VacationManagement/Domain/ValueObjects/DateRange.cs`
- [ ] T003 [S] [US-001] Implement `VacationRequestId`, `EmployeeNotes` (max 500 chars), `VacationStatus` (6-state enum) value objects
- [ ] T004 [L] [US-001] Implement `VacationRequest` aggregate root: `Submit()` factory, `Cancel()`, `TransitionTo()`, `HasOverlapWith()`, all 6 invariants (INV-001–006) — `Domain/VacationRequest.cs`
- [ ] T005 [M] [US-002] Implement `StatusTransition` child entity (append-only, INV-010–012) — `Domain/StatusTransition.cs`
- [ ] T006 [S] [US-001][US-003] Implement `VacationRequestSubmitted` and `VacationRequestCancelled` domain events implementing `IDomainEvent`

### Tests

- [ ] T007 [M] [P] [US-001] xUnit: `DateRange.CalculateBusinessDays` — 20+ parameterized cases (Mon start, Fri end, cross-month, single day, weekend boundaries)
- [ ] T008 [M] [US-001][US-003] xUnit: `VacationRequest` invariants (each INV throws `DomainException`), state machine (all allowed + all forbidden transitions), `HasOverlapWith` edge cases

### Quality Gates — Bolt 1A

- [ ] T009-QG `dotnet build --warnaserror` → 0 warnings
- [ ] T010-QG `dotnet test --filter Category=Unit` → 100% pass
- [ ] T011-QG Coverlet line coverage on Domain project → ≥ 80%
- [ ] T012-QG Coverlet branch coverage → ≥ 75%
- [ ] T013-QG `dotnet stryker --project VacationManagement.Domain.csproj` → mutation score ≥ 70%

---

## Bolt 1B — VacationManagement Persistence & Infrastructure

**Goal:** EF Core context, migrations, repositories, Service Bus publisher.
**Duration:** 2–3 days · **Weight:** 3.5L equivalent

### Entities (Organization — scaffold for F-004)

- [ ] T014 [M] Implement `Employee`, `Department`, `Project`, `EmployeeProject` entities with EF Core configurations — `Infrastructure/Persistence/Configurations/`

### Persistence

- [ ] T015 [M] Implement `VacationManagementDbContext` — `VacationRequest` + `StatusTransition` + Organization entity sets; global query filters for soft-delete
- [ ] T016 [M] [P] EF Core migration `M001_CreateVacationManagementTables` + `M002_CreateOrganizationTables`; verify applied to dev Azure SQL
- [ ] T017 [M] [US-001] Implement `VacationRequestRepository`: `GetByIdAsync`, `SaveAsync`, `HasOverlapAsync`, `GetByEmployeeIdAsync`
- [ ] T018 [M] [US-001] Implement `EmployeeReadRepository` (Dapper): balance check query + org read model (department, project assignment)

### Infrastructure

- [ ] T019 [S] [US-001][US-003] Implement `VacationEventPublisher` — publishes `VacationRequestSubmitted` / `VacationRequestCancelled` to Azure Service Bus
- [ ] T020 [S] Register all module services in `ServiceCollectionExtensions` (CQRS dispatchers, repos, event publisher)

### Tests

- [ ] T021 [M] [P] xUnit + Testcontainers: `VacationRequestRepository` — save, retrieve, `HasOverlapAsync` (overlapping / adjacent / non-overlapping ranges)
- [ ] T022 [M] [P] xUnit + Testcontainers: EF migrations applied cleanly; `Employee` upsert scenarios

### Quality Gates — Bolt 1B

- [ ] T023-QG `dotnet build --warnaserror` → 0 warnings
- [ ] T024-QG `dotnet test` → 100% pass
- [ ] T025-QG Coverlet line coverage (Domain + Infrastructure combined) → ≥ 80%
- [ ] T026-QG Coverlet branch coverage → ≥ 75%
- [ ] T027-QG `dotnet stryker --project VacationManagement.Infrastructure.csproj` → ≥ 70%
- [ ] T028-QG EF migrations applied to dev environment → `/health/ready` returns 200

---

## Bolt 1C — API Layer, Vue SPA & Step Definitions

**Goal:** REST API (4 endpoints), Vue 3 SPA (3 views), Reqnroll step bodies, Vitest + Playwright smoke tests.
**Duration:** 3 days · **Weight:** 4.5L equivalent
> Note: 10 tasks (> 8 limit) but weight 4.5L < 5L and tasks are tightly coupled UI+API; kept as single Bolt.

### Application — CQRS Handlers

- [ ] T029 [M] [US-001] `SubmitVacationRequestCommand` + handler: balance check via `EmployeeReadRepository`; overlap check; publish event; return `VacationRequestId` — `Application/Commands/SubmitVacationRequest/`
- [ ] T030 [M] [US-003] `CancelVacationRequestCommand` + handler: owner check; status guard (`Cancelled`/`Rejected` → 409); idempotency guard — `Application/Commands/CancelVacationRequest/`
- [ ] T031 [M] [US-002] `GetMyVacationRequestsQuery` + handler (Dapper): paginated, status filter, date filter, sorted newest first — `Application/Queries/GetMyVacationRequests/`
- [ ] T032 [M] [US-002] `GetVacationRequestDetailQuery` + handler: owner check; includes `StatusTransition` history — `Application/Queries/GetVacationRequestDetail/`

### API

- [ ] T033 [M] `VacationRequestEndpoints`: `POST /api/vacation-requests`, `GET /api/vacation-requests`, `GET /api/vacation-requests/{id}`, `DELETE /api/vacation-requests/{id}` — all with `RequireEmployee` auth policy

### Frontend

- [ ] T034 [L] [US-001] Vue: `vacationRequestApi.ts` + `vacationRequestStore.ts` (Pinia) + `NewRequestView.vue` + `DateRangePicker.vue` (disabled past dates, live day counter, AC-001.6)
- [ ] T035 [M] [US-002] Vue: `MyRequestsView.vue` + `VacationRequestList.vue` + `StatusBadge.vue` + pagination + status filter (AC-002.1–2.5)
- [ ] T036 [M] [US-002][US-003] Vue: `VacationRequestDetail.vue` + `StatusTimeline.vue` + `CancelConfirmDialog.vue` (confirmation guard for Approved; AC-003.2)

### BDD Step Definitions

- [ ] T037 [M] [P] Implement `VacationRequestSteps.cs` body methods (replace `NotImplementedException` with real assertions against API + DB)

### Tests

- [ ] T038 [M] [P] Vitest: `vacationRequestStore` (submit/cancel/fetch), `DateRangePicker` (disabled dates, day count), `StatusBadge` (colour per status)
- [ ] T039 [S] Reqnroll: run `tests/submit-vacation-request.feature` — all `@smoke` scenarios pass
- [ ] T040 [S] Reqnroll: run `tests/track-vacation-request.feature` + `tests/cancel-vacation-request.feature` — all `@smoke` pass

### Quality Gates — Bolt 1C

- [ ] T041-QG `dotnet format` / `eslint --fix` → 0 errors
- [ ] T042-QG `dotnet test` + `npm test` → 100% pass
- [ ] T043-QG Coverlet BE line coverage → ≥ 80% · Vitest FE coverage → ≥ 80%
- [ ] T044-QG Coverlet branch coverage → ≥ 75%
- [ ] T045-QG-E2E Playwright `@smoke` suite: `vacation-request-submission.spec.ts`, `vacation-request-tracking.spec.ts`, `vacation-request-cancellation.spec.ts` → 0 failures
- [ ] T046-QG NetArchTest suite → all architecture rules pass
- [ ] T047-QG k6 smoke: `POST /api/vacation-requests` P95 < 300 ms
- [ ] T048-QG SAST scan → 0 Critical findings
