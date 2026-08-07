# Technical Plan — F-003: Calendar & Capacity Visualization

## Metadata

| Property          | Value                                               |
| ----------------- | --------------------------------------------------- |
| Feature           | F-003 — Calendar & Capacity Visualization           |
| Scenario          | Fullstack (backend + frontend + cloud-platform)     |
| Bounded Context   | CapacityManagement (Supporting Domain)              |
| Bolt              | Bolt 3 — Week 9–10                                  |
| Issue             | gh#4                                                |
| Author            | Bolt Plan Agent                                     |
| Created           | 2026-08-07                                          |
| Status            | Draft                                               |
| Dependencies      | F-001 complete (VacationRequest data), F-002 complete (Approved status) |

---

## Executive Summary

F-003 delivers the **visual calendar and capacity heat-map** that managers use to assess vacation
coverage at a glance. The key challenge is performance: department-level capacity for 500 employees
across a full year must render in under 1 second. This is achieved through pre-computed
`CapacitySnapshot` records in Azure SQL, backed by a Redis cache (L2, 30 min TTL), invalidated
on every approval/cancellation event via Service Bus.

---

## Architecture Context

| Concern | Decision |
|---------|----------|
| Module | `src/Modules/CapacityManagement/` |
| Pattern | CQRS read-heavy; all queries use Dapper; snapshots computed by event handlers |
| Cache | L1 `IMemoryCache` (5 min) → L2 Redis (30 min); invalidated by Service Bus events |
| Events (inbound) | `VacationRequestSubmitted`, `VacationRequestApprovedFinal`, `VacationRequestCancelled` → recompute snapshots |
| Events (outbound) | `CapacityWarningThresholdCrossed`, `CapacityCriticalThresholdCrossed` → F-006 (alerts) |
| Authorization | Employees: own team only (BR-038); PMs: their project (BR-039); DMs: entire department |
| Frontend | Vue 3; heat-map rendered with CSS grid + computed colour classes |

---

## Bolt Breakdown

| Bolt | Scope | Focus | Duration |
|------|-------|-------|----------|
| **3A** | Backend | CapacitySnapshot entity + computation service + cache + Service Bus consumers | 3 days |
| **3B** | Backend + Frontend | API endpoints + Vue calendar/heat-map/dashboard components | 4 days |

---

## Bolt 3A — Capacity Engine

### Module Structure

```
src/Modules/CapacityManagement/
  ├── Domain/
  │   ├── CapacitySnapshot.cs         ← Aggregate Root
  │   ├── ThresholdConfig.cs          ← Aggregate Root
  │   └── ValueObjects/
  │       ├── CapacitySnapshotId.cs
  │       ├── OrganizationLevel.cs    ← enum: Department, Project, Team
  │       ├── CapacityColor.cs        ← Green/Yellow/Orange/Red
  │       ├── CapacityPeriod.cs       ← DateRange + Granularity
  │       └── AlternativeDateSuggestion.cs
  ├── Application/
  │   ├── Commands/
  │   │   ├── RecomputeCapacitySnapshots/
  │   │   │   ├── RecomputeCapacitySnapshotsCommand.cs
  │   │   │   └── RecomputeCapacitySnapshotsHandler.cs
  │   │   └── UpdateThresholdConfig/
  │   ├── Queries/
  │   │   ├── GetTeamCalendar/
  │   │   ├── GetCapacityHeatMap/
  │   │   ├── GetDashboardSummary/
  │   │   └── GetCapacityCellDetail/
  │   └── EventHandlers/
  │       ├── VacationRequestSubmittedHandler.cs  ← triggers recompute
  │       ├── VacationApprovedFinalHandler.cs
  │       └── VacationCancelledHandler.cs
  ├── Infrastructure/
  │   ├── Persistence/
  │   │   ├── CapacitySnapshotRepository.cs       ← upsert by (Date, Level, EntityId)
  │   │   └── ThresholdConfigRepository.cs
  │   ├── Cache/
  │   │   └── CapacityCacheService.cs             ← L1+L2 cache-aside
  │   └── ServiceBus/
  │       └── CapacityEventPublisher.cs
  └── Api/
      └── CapacityEndpoints.cs
```

### Implementation Checklist — Bolt 3A

- [ ] `CapacitySnapshot` aggregate — `ComputePercentage()`, `IsCriticalFor(ThresholdConfig)`
- [ ] `ThresholdConfig` aggregate — INV-210–213; `GetApplicableConfig(deptId)` resolves dept override vs global
- [ ] `RecomputeCapacitySnapshotsHandler` — upsert snapshots for the affected date range; batched by org level
- [ ] `CapacityCacheService` — L1/L2 Cache-Aside: `GetOrComputeAsync`, `InvalidateAsync(level, entityId, dateRange)`
- [ ] Service Bus consumer: `VacationRequestSubmittedHandler` → `RecomputeCapacitySnapshotsCommand`
- [ ] Service Bus consumer: `VacationApprovedFinalHandler` → `RecomputeCapacitySnapshotsCommand`
- [ ] Service Bus consumer: `VacationCancelledHandler` → `RecomputeCapacitySnapshotsCommand` + capacity recalc
- [ ] `CapacityEventPublisher` — `CapacityWarningThresholdCrossed` / `CapacityCriticalThresholdCrossed` (BR-098 dedup via `CapacityAlert` table)
- [ ] `AlternativeDateSuggestion` — suggests date ranges where `CapacityPercent < WarningThreshold` (BR-044b)
- [ ] EF Core migration: `M004_CreateCapacityManagementTables`
- [ ] Seed initial `ThresholdConfig` (global: warning=65, critical=70)

**Capacity computation logic**

```csharp
// For each date in the affected range, per org level:
// 1. Query total active employees at that level on that date
// 2. Query approved vacations covering that date
// 3. Query pending vacations covering that date
// 4. Compute: (approved + pending) / total × 100
// 5. Upsert CAPACITY_SNAPSHOTS row
// 6. If crosses threshold: publish CapacityThresholdCrossed event
```

---

## Bolt 3B — API Layer & Vue SPA

### Backend — API Endpoints

| Method | Route | Handler | Auth | Cache |
|--------|-------|---------|------|-------|
| `GET` | `/api/capacity/calendar` | `GetTeamCalendarHandler` | Any authenticated | Redis 30 min |
| `GET` | `/api/capacity/heat-map` | `GetCapacityHeatMapHandler` | PM + DM | Redis 30 min |
| `GET` | `/api/capacity/dashboard` | `GetDashboardSummaryHandler` | PM + DM | Redis 30 min |
| `GET` | `/api/capacity/cell/{date}/{level}/{entityId}` | `GetCapacityCellDetailHandler` | PM + DM | No cache (drill-down) |
| `PUT` | `/api/capacity/thresholds` | `UpdateThresholdConfigHandler` | Admin | No cache |

**Heat-map response DTO**

```csharp
record CapacityHeatMapDto(
    IReadOnlyList<CapacityDayDto> Days
);
record CapacityDayDto(
    DateOnly Date,
    int TotalEmployees,
    int OnVacation,
    int Pending,
    decimal Percentage,
    string Color,     // "green" | "yellow" | "orange" | "red"
    bool IsCritical,
    bool IsWarning
);
```

**Calendar response DTO**

```csharp
record TeamCalendarDto(
    IReadOnlyList<EmployeeVacationRowDto> Rows
);
record EmployeeVacationRowDto(
    Guid EmployeeId,
    string EmployeeName,
    IReadOnlyList<VacationPeriodDto> Periods   // approved + pending
);
record VacationPeriodDto(DateOnly Start, DateOnly End, string Status, string Color);
```

### Frontend Tasks — Vue 3 SPA

```
src/frontend/src/modules/capacity/
  ├── views/
  │   ├── TeamCalendarView.vue        ← US-008
  │   ├── CapacityHeatMapView.vue     ← US-009
  │   └── DashboardView.vue           ← US-010
  ├── components/
  │   ├── CalendarGrid.vue            ← employee rows × date columns
  │   ├── HeatMapGrid.vue             ← date cells colour-coded by capacity
  │   ├── CapacityCell.vue            ← click → drill-down (AC-009.6)
  │   ├── CapacityCellDetail.vue      ← drawer/modal with employee list + alt dates
  │   ├── DashboardMetrics.vue        ← current vacations, available, pending approvals
  │   ├── OverCapacityAlertCard.vue   ← red card for periods > 70% (AC-010.2)
  │   ├── OrgLevelSelector.vue        ← Department / Project / Team (US-011)
  │   ├── DateRangeFilter.vue
  │   └── AlternativeDatesPanel.vue   ← suggested dates (BR-044b)
  ├── stores/
  │   ├── calendarStore.ts
  │   └── dashboardStore.ts
  └── api/
      └── capacityApi.ts
```

**Implementation checklist — Bolt 3B frontend**

- [ ] `HeatMapGrid.vue` — CSS grid; colour computed from `CapacityColor` enum (AC-009.2–9.5)
- [ ] `CapacityCell.vue` — click handler opens `CapacityCellDetail` with employee list (AC-009.6)
- [ ] `AlternativeDatesPanel.vue` — displays `AlternativeDateSuggestion[]` (AC-009.7, BR-044b)
- [ ] `CalendarGrid.vue` — employee rows × date columns; approved=green, pending=yellow (AC-008.2)
- [ ] `OrgLevelSelector.vue` — DM can select Department/Project; PM limited to Project/Team (BR-051)
- [ ] Weekly / monthly view toggle (AC-008.3)
- [ ] `DashboardMetrics.vue` — current vacation count, available employees, pending approvals (AC-010.1)
- [ ] `OverCapacityAlertCard.vue` — shows all critical periods within next 90 days (AC-010.2, BR-048)
- [ ] Lighthouse performance ≥ 90 for calendar render (NFR-020)
- [ ] Render time ≤ 1s for 50 employees × 1 month (AC-008.6) — virtual scrolling if needed

---

## Test Strategy

### Backend

| Type | Key Scenarios |
|------|---------------|
| Domain Unit | `CapacityColor.FromPercentage()` — boundary values: 50%, 64%, 65%, 70%, 71% |
| Domain Unit | `ThresholdConfig.IsApplicableTo()` — dept config overrides global |
| Domain Unit | `AlternativeDateSuggestion` — finds low-capacity window in next 30 days |
| Application Unit | `RecomputeCapacitySnapshotsHandler` — correct snapshot values for 3-employee team |
| Integration | Event handler → snapshot upserted → Redis invalidated |
| Integration | Cache-aside: miss → DB → Redis populated |
| BDD | AC-009.1 `@smoke` — capacity view shows percentages per day |
| BDD | AC-009.5 `@smoke` — period > 70% shown as Critical (red) |
| k6 Performance | `/api/capacity/heat-map` — P95 < 1s for dept with 500 employees, 90-day window |

### Frontend

| Type | Key Scenarios |
|------|---------------|
| Component | `CapacityCell` — correct colour class for each percentage band |
| Component | `AlternativeDatesPanel` — renders suggestion list |
| E2E | `@smoke` — DM views heat-map and sees critical period highlighted |
| E2E | `@smoke` — PM views team calendar with pending/approved periods |
| E2E | DM clicks critical cell → sees employee list + alternative dates |
| Lighthouse | Calendar page performance score ≥ 90 |

---

## Quality Gates

| Gate | Threshold |
|------|-----------|
| Line coverage | ≥ 80% |
| Branch coverage | ≥ 75% |
| Linting | 0 errors |
| Architecture | All NetArchTest rules pass |
| BDD `@smoke` | 100% |
| Playwright `@smoke` | 100% |
| Calendar P95 render | < 1 s (k6) |
| Heat-map P95 render | < 1 s (k6) |

---

## Risks & Mitigations

| Risk | Prob | Impact | Mitigation |
|------|------|--------|------------|
| Snapshot recompute cascades — approval of 100 requests triggers 100 recomputes | High | High | Debounce via Service Bus message deduplication; batch recompute by entity ID |
| Redis cache inconsistency under high concurrency | Medium | Medium | Use Redis `WATCH`/`MULTI` for atomic cache set; TTL prevents stale data > 30 min |
| Calendar render slow for large teams (50+ employees × 90 days) | High | High | Virtual scrolling on employee rows; lazy-load months on demand |
| Threshold config not set → division by zero if `TotalEmployees = 0` | Low | High | Guard: return 0% if `TotalEmployees == 0`; log warning |

---

## Dependencies

| Dependency | Type | Status |
|-----------|------|--------|
| F-001 — `VacationRequest` with Status and DateRange | Hard | Bolt 3A blocked until F-001 deployed |
| F-002 — `VacationApprovedFinal` event must be published | Hard | Bolt 3A event handler needs this event |
| Redis provisioned (Phase 4) | Hard | `CapacityCacheService` requires Redis connection |
| Service Bus topic: `capacity.threshold.crossed` | Hard | Provisioned in Phase 4 |

---

## Open Research Items

| Item | Priority | Owner |
|------|----------|-------|
| Q-007: Does capacity include Pending requests or Approved only? | Resolved | BR-043: both Approved + Pending count |
| Q-008: Employees see department or team-level heat-map? | Open | Confirm with PO — suggest team-level only for employees |
| Q-009: Exact visual spec for "very visual" calendar | Open | UX Designer — mockup required before Bolt 3B start |
