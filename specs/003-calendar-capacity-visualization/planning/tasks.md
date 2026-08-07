# Task List — F-003: Calendar & Capacity Visualization

## Metadata

| Property       | Value                                               |
| -------------- | --------------------------------------------------- |
| Feature        | F-003 — Calendar & Capacity Visualization           |
| Scenario       | Fullstack (backend + frontend + cloud-platform)     |
| Source plan    | `planning/plan.md`                                  |
| Gherkin source | `tests/team-calendar.feature` · `tests/capacity-heat-map.feature` · `tests/executive-dashboard.feature` |
| Steps stub     | `tests/CapacityManagement.ReqnrollTests/StepDefinitions/CalendarCapacitySteps.cs` |
| Created        | 2026-08-07                                          |
| Status         | Ready for execution                                 |

---

## Reconciliation plan ↔ Gherkin

### Coverage

| Metric | Count |
|--------|-------|
| Endpoints planned | 5 |
| Endpoints with BDD coverage | 5 |
| `@smoke` scenarios | 9 (2 calendar + 3 heat-map + 2 dashboard + 2 org-level) |
| `@smoke` with planned implementation | 9 |
| Gaps | 1 (minor) |

### Gaps detected

- **Minor gap:** US-011 (organizational level selection) has `@smoke` scenarios in `executive-dashboard.feature` but has no dedicated `.feature` file. Plan includes `OrgLevelSelector.vue` component and `GetTeamCalendarQuery` with level param — **T022 added** explicitly for US-011 org-level selector component and query parameter validation.
- Step definitions stub → **T028** added in Bolt 3B.

---

## Auto-Split Log

| Original Bolt | Decision | Reason |
|--------------|----------|--------|
| Bolt 3A (capacity engine) | **Split → Bolt 3A + Bolt 3B** | 12 tasks > 8-task limit |
| Bolt 3B was (API + frontend) | Renamed → **Bolt 3C**; kept (9 tasks, 4.5L) | Weight within limit |

---

## User Story → Bolt Map

| User Story | Priority | Bolt |
|-----------|---------|------|
| US-008 Team Calendar View | P1 | Bolt 3A + 3C |
| US-009 Capacity Heat Map | P1 | Bolt 3A + 3C |
| US-010 Executive Dashboard | P1 | Bolt 3C |
| US-011 Organizational Level Selection | P2 | Bolt 3B + 3C |

---

## Bolt 3A — CapacityManagement Domain & Engine

**Goal:** Domain aggregates, computation service, Service Bus consumers, Redis cache layer.
**Duration:** 3 days · **Weight:** 4.5L equivalent

### Domain

- [x] T001 [S] Create `src/Modules/CapacityManagement/` folder structure
- [x] T002 [M] [US-009] Implement `CapacitySnapshot` aggregate root: `ComputePercentage()`, `IsCriticalFor(ThresholdConfig)`, `IsWarning`; `INV-201–204`
- [x] T003 [M] [US-009] Implement `ThresholdConfig` aggregate root: `IsApplicableTo(deptId)`, `INV-210–213`; dept override > global resolution
- [x] T004 [S] Implement `CapacityPeriod` VO (`GetDates()`), `CapacityColor` enum + `FromPercentage()`, `AlternativeDateSuggestion` VO

### Infrastructure — Computation

- [x] T005 [L] [US-008][US-009] `RecomputeCapacitySnapshotsHandler`: upsert snapshots for affected `(Date, Level, EntityId)` range; batch by org level; guard `TotalEmployees == 0`; fire `CapacityWarningThresholdCrossed` / `CapacityCriticalThresholdCrossed` events with dedup check
- [ ] T006 [M] [P] `CapacityCacheService`: L1 `IMemoryCache` (5 min) + L2 Redis (30 min) Cache-Aside; `GetOrComputeAsync`; `InvalidateAsync(level, entityId, dateRange)`
- [ ] T007 [M] EF Core config for `CapacitySnapshot` + `ThresholdConfig`; unique constraint `UQ_CS_Date_Level_Entity`; `IX_CS_Critical_Date` for next-90-days query
- [ ] T008 [M] [P] Migration `M004_CreateCapacityManagementTables`; seed global `ThresholdConfig` (warning=65, critical=70)

### Service Bus Consumers

- [ ] T009 [M] [US-009] `VacationRequestSubmittedHandler` → triggers `RecomputeCapacitySnapshotsCommand` for affected date range
- [ ] T010 [M] [US-009] `VacationApprovedFinalHandler` + `VacationCancelledHandler` → same recompute + cache invalidation

### Tests

- [x] T011 [M] [US-009] xUnit: `CapacityColor.FromPercentage` boundary values (50%, 64%, 65%, 70%, 71%); `ThresholdConfig` dept-overrides-global; `AlternativeDateSuggestion` generation
- [x] T012 [M] [P] xUnit + Testcontainers: `RecomputeCapacitySnapshotsHandler` with 3-employee team — correct snapshot values; event fired when threshold crossed; `CapacityCacheService` miss → DB → Redis populated

### Quality Gates — Bolt 3A

- [x] T013-QG `dotnet build --warnaserror` → 0 warnings
- [x] T014-QG `dotnet test` → 100% pass
- [x] T015-QG Coverlet line ≥ 80% / branch ≥ 75%
- [ ] T016-QG `dotnet stryker --project CapacityManagement.Domain.csproj` → ≥ 70%

---

## Bolt 3B — API Queries, ThresholdConfig Management & Org-Level

**Goal:** 5 API endpoints, all Dapper query handlers, threshold update command.
**Duration:** 2 days · **Weight:** 3.0L equivalent

### Application — Queries

- [ ] T017 [M] [US-008] `GetTeamCalendarQuery` + handler (Dapper): employee rows × date columns; status per period; scoped by role (employee=own team, PM=project, DM=department; BR-038–039)
- [ ] T018 [M] [US-009] `GetCapacityHeatMapQuery` + handler (Dapper): reads `CAPACITY_SNAPSHOTS`; returns `CapacityDayDto[]` with colour; department-scoped
- [ ] T019 [M] [US-010] `GetDashboardSummaryQuery` + handler (Dapper): current vacations, available employees, pending count, avg approval time (last 30d), over-capacity periods next 90 days
- [ ] T020 [M] [US-009] `GetCapacityCellDetailQuery` + handler: employees contributing to a specific date cell + `AlternativeDateSuggestion[]` (BR-044b)
- [ ] T021 [M] [US-011] `UpdateThresholdConfigCommand` + handler (validates critical > warning; dept override logic; BR-125)

### Org-Level Gap Fix

- [ ] T022 [M] [US-011] Extend `GetTeamCalendarQuery` and `GetCapacityHeatMapQuery` to accept `OrganizationLevel` + `LevelEntityId` parameters; enforce DM-can-query-all / PM-limited-to-project (BR-051)

### API

- [ ] T023 [M] `CapacityEndpoints`: `GET /api/capacity/calendar`, `GET /api/capacity/heat-map`, `GET /api/capacity/dashboard`, `GET /api/capacity/cell/{date}/{level}/{entityId}`, `PUT /api/capacity/thresholds` (Admin only)

### Tests

- [ ] T024 [M] [P] xUnit: `GetDashboardSummaryQuery` — DM sees department scope only; PM sees project scope only
- [ ] T025 [M] [P] xUnit: `UpdateThresholdConfigCommand` — validation (1–100 range; critical > warning); dept override created and retrieved correctly

### Quality Gates — Bolt 3B

- [ ] T026-QG `dotnet build --warnaserror` → 0 warnings
- [ ] T027-QG `dotnet test` → 100% pass
- [ ] T028-QG Coverlet line ≥ 80% / branch ≥ 75%
- [ ] T029-QG k6 smoke: `GET /api/capacity/heat-map` P95 < 1 s (dept, 500 employees, 90-day window)

---

## Bolt 3C — Vue SPA, Step Definitions & E2E

**Goal:** Calendar grid, heat-map, dashboard Vue components; Reqnroll step bodies; Playwright smoke.
**Duration:** 3 days · **Weight:** 4.5L equivalent

### Frontend

- [ ] T030 [M] [US-008] Vue: `calendarStore.ts` + `TeamCalendarView.vue` + `CalendarGrid.vue` (rows=employees, cols=weekdays; colour bars by status; weekly/monthly toggle; AC-008.2–3)
- [ ] T031 [L] [US-009] Vue: `HeatMapGrid.vue` + `CapacityCell.vue` (click → drill-down) + `CapacityCellDetail.vue` (employee list + `AlternativeDatesPanel.vue`); correct colour class for each band (AC-009.2–9.7)
- [ ] T032 [M] [US-010][US-011] Vue: `DashboardView.vue` + `DashboardMetrics.vue` + `OverCapacityAlertCard.vue` (next 90 days; AC-010.1–2) + `OrgLevelSelector.vue` (DM=all levels; PM=project/team; BR-051)

### BDD Step Definitions

- [ ] T033 [M] [P] Implement `CalendarCapacitySteps.cs` body methods for all 3 `.feature` files

### Tests

- [ ] T034 [M] Vitest: `CapacityCell` colour class for each % band; `AlternativeDatesPanel` renders suggestions; `DashboardMetrics` correct counts
- [ ] T035 [S] Reqnroll: all `@smoke` in `team-calendar.feature`, `capacity-heat-map.feature`, `executive-dashboard.feature`

### Quality Gates — Bolt 3C

- [ ] T036-QG `dotnet format` / `eslint` → 0 errors
- [ ] T037-QG `dotnet test` + `npm test` → 100% pass
- [ ] T038-QG Coverlet BE ≥ 80%; Vitest FE ≥ 80%
- [ ] T039-QG-E2E Playwright `@smoke`: `calendar-capacity.spec.ts` → 0 failures (DM views heat-map critical cell; PM views team calendar)
- [ ] T040-QG Lighthouse CI: calendar page performance score ≥ 90
- [ ] T041-QG axe-core accessibility: all 3 views WCAG 2.1 AA
- [ ] T042-QG NetArchTest → all rules pass
- [ ] T043-QG SAST scan → 0 Critical
