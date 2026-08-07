# Technical Plan — F-001: Vacation Request Management

## Metadata

| Property          | Value                                              |
| ----------------- | -------------------------------------------------- |
| Feature           | F-001 — Vacation Request Management                |
| Scenario          | Fullstack (backend + frontend + cloud-platform)    |
| Bounded Context   | VacationManagement (Core Domain)                   |
| Bolt              | Bolt 1 — Week 5–6                                  |
| Issue             | gh#2                                               |
| Author            | Bolt Plan Agent                                    |
| Created           | 2026-08-07                                         |
| Status            | Draft                                              |
| Dependencies      | Phase 4 (infrastructure) complete; Entra ID tenant ready |

---

## Executive Summary

F-001 is the **foundational feature** of the entire system. It introduces the
`VacationRequest` aggregate, the `Employee`/`Department`/`Project` organization
model, and the vacation submission/tracking/cancellation flows. Every subsequent
feature depends on the entities and domain events produced here.

The feature is a two-Bolt delivery: Bolt 1A builds the domain core and persistence
layer; Bolt 1B implements the API and frontend SPA.

---

## Architecture Context

Constraints from the Bolt Framework Constitution:

| Concern | Decision |
|---------|----------|
| Backend | C# / .NET 10 · Minimal APIs · Modular Monolith (`src/Modules/VacationManagement/`) |
| Pattern | Simple CQRS — no MediatR; manual dispatcher via DI |
| ORM | EF Core 10 (writes) + Dapper (reads/queries) |
| Auth | JWT Bearer — Entra ID; policy `RequireEmployee` |
| Cache | `IMemoryCache` L1 (5 min) → Redis L2 (30 min) for read queries |
| Events | Azure Service Bus — `vacation.submitted`, `vacation.cancelled` topics |
| Frontend | Vue 3 · TypeScript · Pinia · Vite · Azure Static Web Apps |
| Auth SPA | MSAL.js v3 — Auth Code + PKCE |
| Tests BE | xUnit · Testcontainers (SQL Server) · Reqnroll (BDD) |
| Tests FE | Vitest · Vue Testing Library · Playwright E2E |
| Coverage | ≥ 80% line, ≥ 75% branch (enforced by CI gate) |

---

## Bolt Breakdown

| Bolt | Scope | Focus | Duration |
|------|-------|-------|----------|
| **1A** | Backend | Domain model + persistence + CQRS skeleton | 3 days |
| **1B** | Backend + Frontend | API endpoints + Vue SPA (submit, track, cancel) | 4 days |

---

## Bolt 1A — Domain Model & Persistence

### Backend Tasks

**Module scaffold**

```
src/Modules/VacationManagement/
  ├── Domain/
  │   ├── VacationRequest.cs          ← Aggregate Root
  │   ├── StatusTransition.cs         ← Child Entity
  │   ├── ValueObjects/
  │   │   ├── VacationRequestId.cs
  │   │   ├── DateRange.cs            ← CalculateBusinessDays()
  │   │   ├── EmployeeNotes.cs
  │   │   └── VacationStatus.cs      ← enum (6 states)
  │   └── Events/
  │       ├── VacationRequestSubmitted.cs
  │       └── VacationRequestCancelled.cs
  ├── Application/
  │   ├── Commands/
  │   │   ├── SubmitVacationRequest/
  │   │   │   ├── SubmitVacationRequestCommand.cs
  │   │   │   ├── SubmitVacationRequestHandler.cs
  │   │   │   └── SubmitVacationRequestValidator.cs
  │   │   └── CancelVacationRequest/
  │   │       ├── CancelVacationRequestCommand.cs
  │   │       └── CancelVacationRequestHandler.cs
  │   └── Queries/
  │       ├── GetMyVacationRequests/
  │       │   ├── GetMyVacationRequestsQuery.cs
  │       │   ├── GetMyVacationRequestsHandler.cs   ← Dapper
  │       │   └── VacationRequestSummaryDto.cs
  │       └── GetVacationRequestDetail/
  │           ├── GetVacationRequestDetailQuery.cs
  │           └── VacationRequestDetailDto.cs
  ├── Infrastructure/
  │   ├── Persistence/
  │   │   ├── VacationManagementDbContext.cs
  │   │   ├── VacationRequestRepository.cs
  │   │   └── Configurations/
  │   │       ├── VacationRequestConfiguration.cs
  │   │       └── StatusTransitionConfiguration.cs
  │   └── ServiceBus/
  │       └── VacationEventPublisher.cs
  └── Api/
      └── VacationRequestEndpoints.cs
```

**Implementation checklist — Bolt 1A**

- [ ] `VacationRequest` aggregate with all 6 invariants (INV-001 – INV-006)
- [ ] `DateRange.CalculateBusinessDays()` — Mon–Fri, no weekends (BR-003)
- [ ] `EmployeeNotes.Create()` — max 500 chars validation (BR-005)
- [ ] `VacationRequest.Submit()` factory — raises `VacationRequestSubmitted`
- [ ] `VacationRequest.Cancel()` — raises `VacationRequestCancelled`
- [ ] `VacationRequest.TransitionTo()` — validates allowed state transitions
- [ ] `VacationRequest.HasOverlapWith(DateRange)` — pure query for overlap check
- [ ] EF Core `VacationManagementDbContext` with `VacationRequest` + `StatusTransition` config
- [ ] EF Core migration: `M001_CreateVacationManagementTables`
- [ ] `VacationRequestRepository` (IRepository pattern): `GetByIdAsync`, `SaveAsync`, `GetByEmployeeIdAsync`
- [ ] `VacationEventPublisher` — publishes to Service Bus `vacation.submitted` / `vacation.cancelled`
- [ ] Organization read model: `EmployeeReadRepository` (Dapper) — balance check query (BR-006c)
- [ ] Register module services in `ServiceCollectionExtensions`

**Organization module (pre-requisite — scaffold only)**

- [ ] `Employee` entity + EF config (fields: ExternalAdId, FullName, Email, DepartmentId, ManagerId, Role, IsActive, VacationBalance fields)
- [ ] `Department` entity + EF config
- [ ] `Project` entity + `EmployeeProject` join table
- [ ] Migration: `M002_CreateOrganizationTables`

---

## Bolt 1B — API Layer & Vue SPA

### Backend Tasks — API Endpoints

File: `src/Modules/VacationManagement/Api/VacationRequestEndpoints.cs`

| Method | Route | Handler | Auth Policy | Notes |
|--------|-------|---------|-------------|-------|
| `POST` | `/api/vacation-requests` | `SubmitVacationRequestHandler` | `RequireEmployee` | Returns 201 + `{ id, status, totalDays }` |
| `GET` | `/api/vacation-requests` | `GetMyVacationRequestsHandler` | `RequireEmployee` | Paginated, filterable by status/date |
| `GET` | `/api/vacation-requests/{id}` | `GetVacationRequestDetailHandler` | `RequireEmployee` | Includes full status timeline |
| `DELETE` | `/api/vacation-requests/{id}` | `CancelVacationRequestHandler` | `RequireEmployee` | Returns 200 on success |

**Request/Response contracts**

```csharp
// POST /api/vacation-requests
record SubmitVacationRequestRequest(
    DateOnly StartDate,
    DateOnly EndDate,
    string? Notes
);
record SubmitVacationRequestResponse(
    Guid Id,
    string Status,
    int TotalBusinessDays,
    DateOnly StartDate,
    DateOnly EndDate
);

// GET /api/vacation-requests
record VacationRequestListResponse(
    IReadOnlyList<VacationRequestSummaryDto> Items,
    int TotalCount,
    int Page,
    int PageSize
);

// GET /api/vacation-requests/{id}
record VacationRequestDetailResponse(
    Guid Id,
    string Status,
    DateOnly StartDate,
    DateOnly EndDate,
    int TotalBusinessDays,
    string? Notes,
    DateTime CreatedAt,
    IReadOnlyList<StatusTransitionDto> History
);
```

**Validation rules (FluentValidation or inline)**

| Field | Rule |
|-------|------|
| `StartDate` | Required; ≥ today + 1 business day (BR-002) |
| `EndDate` | Required; > `StartDate` (BR-001) |
| `Notes` | Optional; ≤ 500 chars (BR-005) |
| Balance check | `VacationBalance.HasSufficientBalance(totalDays)` (BR-006c) |
| Overlap check | `VacationRequestRepository.HasOverlap(employeeId, dateRange)` (BR-004) |

**Error responses**

| Scenario | HTTP Status | Error Code |
|----------|-------------|------------|
| Date validation failed | 422 | `DATE_VALIDATION_ERROR` |
| Overlapping request | 409 | `OVERLAPPING_REQUEST` |
| Insufficient balance | 422 | `INSUFFICIENT_BALANCE` |
| Request not found | 404 | `REQUEST_NOT_FOUND` |
| Not owner | 403 | `FORBIDDEN` |
| Already cancelled/rejected | 409 | `INVALID_STATUS_TRANSITION` |

### Frontend Tasks — Vue 3 SPA

**Module structure**

```
src/frontend/src/modules/vacation-requests/
  ├── views/
  │   ├── MyRequestsView.vue          ← US-002
  │   └── NewRequestView.vue          ← US-001
  ├── components/
  │   ├── VacationRequestList.vue
  │   ├── VacationRequestCard.vue
  │   ├── VacationRequestDetail.vue   ← with StatusTimeline
  │   ├── DateRangePicker.vue         ← visual calendar (AC-001.6)
  │   ├── StatusBadge.vue             ← colour-coded by status
  │   ├── StatusTimeline.vue          ← AC-002.3
  │   └── CancelConfirmDialog.vue     ← AC-003.2
  ├── stores/
  │   └── vacationRequestStore.ts     ← Pinia store
  ├── composables/
  │   ├── useVacationRequests.ts
  │   └── useBusinessDayCalc.ts       ← client-side day count preview
  ├── api/
  │   └── vacationRequestApi.ts       ← typed Axios calls
  └── types/
      └── vacationRequest.types.ts
```

**Implementation checklist — Bolt 1B frontend**

- [ ] `vacationRequestStore.ts` — Pinia store with `fetchMyRequests`, `submitRequest`, `cancelRequest` actions
- [ ] `NewRequestView.vue` — date picker with disabled past/today dates (AC-001.6); live business-day counter
- [ ] `MyRequestsView.vue` — paginated list with status filter, sort by newest (AC-002.1–2.5)
- [ ] `VacationRequestDetail.vue` — status timeline showing all transitions (AC-002.3)
- [ ] `StatusBadge.vue` — green/yellow/red/grey per status (colour coding from data model)
- [ ] `CancelConfirmDialog.vue` — shown only for Approved requests (AC-003.2)
- [ ] `DateRangePicker.vue` — highlights selected range; disables past dates (AC-001.6, UC-001 step 2)
- [ ] Error toasts for: overlap, insufficient balance, date validation
- [ ] Route guards: `requireEmployee` middleware on all vacation-request routes
- [ ] Responsive: works on desktop (primary device) and mobile (status check)

**Pinia store actions**

```typescript
// vacationRequestStore.ts
interface VacationRequestStore {
  requests: VacationRequestSummary[]
  total: number
  loading: boolean
  fetchMyRequests(filters: RequestFilters): Promise<void>
  submitRequest(data: SubmitRequestPayload): Promise<string>   // returns id
  cancelRequest(id: string): Promise<void>
  fetchDetail(id: string): Promise<VacationRequestDetail>
}
```

---

## Test Strategy

### Backend (xUnit + Testcontainers)

| Layer | Type | Key Scenarios |
|-------|------|---------------|
| Domain | Unit | `DateRange.CalculateBusinessDays` — all edge cases (Mon start, Fri end, cross-month, single day) |
| Domain | Unit | `VacationRequest` invariants (INV-001 – INV-006) — each throws correct `DomainException` |
| Domain | Unit | State machine — all allowed and forbidden transitions |
| Domain | Unit | `HasOverlapWith` — overlapping, adjacent, non-overlapping ranges |
| Application | Unit | `SubmitVacationRequestHandler` — all validation paths (balance fail, overlap fail, date fail) |
| Application | Unit | `CancelVacationRequestHandler` — owner check, status check |
| Integration | SQL Server | `VacationRequestRepository` — save, retrieve, overlap query |
| Integration | SQL Server | EF Core migration applied correctly |
| Integration | Service Bus | `VacationEventPublisher` publishes correct message shape |
| BDD | Reqnroll | AC-001.1, AC-001.2 `@smoke` scenarios |

### Frontend (Vitest + Playwright)

| Layer | Type | Key Scenarios |
|-------|------|---------------|
| Store | Vitest | `submitRequest` success / validation error / server error |
| Store | Vitest | `cancelRequest` idempotency (double-click) |
| Component | Vitest | `DateRangePicker` — disables past dates; shows correct day count |
| Component | Vitest | `StatusBadge` — correct colour per status |
| E2E | Playwright | `@smoke` — Employee submits a new vacation request (AC-001.1) |
| E2E | Playwright | `@smoke` — Employee views My Requests list (AC-002.1) |
| E2E | Playwright | `@smoke` — Employee cancels a pending request (AC-003.1) |
| E2E | Playwright | Employee cancels an approved request with confirmation (AC-003.2) |

---

## Quality Gates (per Bolt)

Both gates must pass before merging to `main`. No exceptions.

| Gate | Threshold | Tool |
|------|-----------|------|
| Line coverage | ≥ 80% | Coverlet (BE) / Vitest (FE) |
| Branch coverage | ≥ 75% | Coverlet |
| Linting | 0 errors | `dotnet build --warnaserror` + ESLint |
| Architecture | All rules pass | NetArchTest |
| BDD `@smoke` | 100% pass | Reqnroll CI stage |
| Playwright `@smoke` | 100% pass | Playwright CI stage |
| SAST | 0 Critical | Pipeline SAST scan |
| API P95 latency | < 300 ms | k6 smoke (per Bolt 1B) |

---

## Risks & Mitigations

| Risk | Prob | Impact | Mitigation |
|------|------|--------|------------|
| `CalculateBusinessDays` edge cases (month boundary, single day) | High | Medium | Exhaustive parameterized unit tests covering ≥ 20 cases |
| EF Core migration conflicts across parallel feature branches | Medium | Medium | Single migration owner per sprint; rebase before PR |
| Entra ID SPA registration not ready | Medium | High | Fallback to Mock IDP (dev); request registration in Week 1 |
| `VacationBalance` from ServiceNow not available in Phase 1 setup | Medium | High | Seed test balance data via admin script until F-005 import is live |
| DateRangePicker accessibility (keyboard navigation) | Low | Medium | Validate with axe-core in Playwright during Bolt 1B |

---

## Dependencies

| Dependency | Type | Status |
|-----------|------|--------|
| Phase 4 infrastructure (Azure Container Apps, Azure SQL, Redis, Service Bus) | Hard | Required before Bolt 1A deploy |
| Entra ID app registration (dev tenant) | Hard | Required before Bolt 1B frontend auth |
| F-002 (ApprovalWorkflow) | Soft | `TransitionTo()` hook must be in place; F-002 implements callers |
| F-005 (ServiceNow import) | Soft | `VacationBalance` fields seeded manually until F-005 complete |

---

## Open Research Items

| Item | Priority | Owner |
|------|----------|-------|
| Confirm minimum advance notice: 1 business day (CL-001) | Resolved | BR-002 |
| Date picker library choice for Vue 3 (native vs. library) | Medium | Tech Lead |
| Service Bus topic/subscription naming convention | Low | Platform Engineer |
