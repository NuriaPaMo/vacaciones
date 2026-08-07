# Task List — F-007: Reporting & Administration

## Metadata

| Property       | Value                                               |
| -------------- | --------------------------------------------------- |
| Feature        | F-007 — Reporting & Administration                  |
| Scenario       | Fullstack (backend + frontend + cloud-platform)     |
| Source plan    | `planning/plan.md`                                  |
| Gherkin source | `tests/vacation-history-report.feature` · `tests/audit-trail.feature` · `tests/system-configuration.feature` · `tests/user-role-management.feature` |
| Steps stub     | `tests/ReportingAdmin.ReqnrollTests/StepDefinitions/ReportingAdminSteps.cs` |
| Created        | 2026-08-07                                          |
| Status         | Ready for execution                                 |

---

## Reconciliation plan ↔ Gherkin

### Coverage

| Metric | Count |
|--------|-------|
| Endpoints planned | 15 (5 reports + 2 audit + 4 admin config + 4 user mgmt) |
| Endpoints with BDD coverage | 13 |
| `@smoke` scenarios | 14 (2 report + 2 audit + 2 config + 2 user + extras) |
| `@smoke` with planned implementation | 14 |
| Gaps | 2 (minor) |

### Gaps detected

- **Minor gap 1:** US-024 (Approval Time Report) and US-025 (Coverage Report) have `@smoke` scenarios referenced in `.feature` files but no dedicated `.feature` file was generated. → **T013 added**: "Create `approval-time-report.feature` + `coverage-report.feature` Gherkin and implement steps." These are P2 stories; scheduled in Bolt 7B.
- **Minor gap 2:** Report export endpoints (`POST /api/reports/export`, `GET /api/reports/export/{id}`) have no `@smoke` BDD coverage. Export is an async flow — documented as deliberately excluded from BDD (polling not well-suited for Reqnroll sync scenarios). Covered instead by Vitest + Playwright E2E stub.
- Step definitions stub → **T042** in Bolt 7B.

---

## Auto-Split Log

| Original Bolt | Decision | Reason |
|--------------|----------|--------|
| Bolt 7A (audit + config + reports) | **Split → Bolt 7A + Bolt 7B** | 14 tasks > 8-task limit |
| Bolt 7B (export + admin UI) | **Split → Bolt 7B + Bolt 7C** | 13 tasks > 8-task limit |

---

## User Story → Bolt Map

| User Story | Priority | Bolt |
|-----------|---------|------|
| US-026 Audit Trail | P1 | Bolt 7A |
| US-027 System Configuration | P1 | Bolt 7A |
| US-023 Vacation History Report | P1 | Bolt 7B |
| US-028 User & Role Management | P1 | Bolt 7B |
| US-024 Approval Time Report | P2 | Bolt 7B |
| US-025 Coverage Report | P2 | Bolt 7B |
| Report export (CSV/Excel/PDF) | P1 | Bolt 7C |
| Frontend admin panel | P1 | Bolt 7C |

---

## Bolt 7A — Audit Interceptor, SystemConfiguration & Core Queries

**Goal:** EF Core `AuditInterceptor`, `SystemConfiguration` aggregate, report read models, admin config command.
**Duration:** 3 days · **Weight:** 4.5L equivalent

### Domain

- [ ] T001 [S] Create `src/Modules/ReportingAdmin/` folder structure
- [ ] T002 [M] [US-026] Implement `AuditEntry` aggregate root: immutable constructor; `INV-601–604`; `[AuditRedact]` attribute for PII field redaction
- [ ] T003 [M] [US-027] Implement `SystemConfiguration` aggregate root: `Update(newValue, updatedBy)` captures `PreviousValue`; `GetValue<T>()` deserialization; `INV-610–614`

### Infrastructure — Audit Interceptor

- [ ] T004 [L] [US-026] Implement `AuditInterceptor` (`SaveChangesInterceptor`): captures all `Added`/`Modified`/`Deleted` `EntityEntry` states; excludes `AuditEntry` itself (prevent recursion); serializes `OldValuesJson` / `NewValuesJson` with PII redaction; sets `Source` from `IAuditContext`; writes in **same transaction** as the change
- [ ] T005 [M] [P] EF Core config for `AuditEntry` (append-only — `HasNoUpdate()` + `HasNoDelete()` fluent config); `SystemConfiguration` + `ReportExecution`; indexes `IX_AE_Timestamp`, `IX_AE_UserId_Timestamp`, `IX_AE_EntityType_EntityId`, `IX_AE_ActionType_Timestamp`; unique `UQ_SC_Key_Scope_DepartmentId`
- [ ] T006 [M] [P] Migration `M008_CreateReportingAdminTables` + `M009_SeedSystemConfigurations` (default config values: thresholds, escalation timeframes, cron schedules)

### Application — Queries (Dapper)

- [ ] T007 [M] [US-023] `GetVacationHistoryReportQuery` + handler: Dapper join (VR + Employee + Department + Project + ApprovalStep); scoped to DM department (BR-103); max 2-year range (BR-107); `PagedResult<VacationHistoryReportRow>` response
- [ ] T008 [M] [US-026] `GetAuditTrailQuery` + handler: Dapper; paginated (50/page); filterable by `UserId`, date range, `ActionType`, `EntityType`, `EntityId`; < 2s for 1M entries (covered-index query)
- [ ] T009 [M] [US-027] `GetSystemConfigurationsQuery` + handler: returns global + dept-specific configs; effective value resolution (dept > global; BR-124)

### Application — Commands

- [ ] T010 [M] [US-027] `UpdateSystemConfigurationCommand` + handler: validates 1–100 range (BR-125); validates critical > warning; captures `PreviousValue`; emits audit entry; takes effect immediately (BR-122)

### Tests

- [ ] T011 [M] [US-026] xUnit: `AuditInterceptor` — saving `VacationRequest` produces `AuditEntry(ActionType=Created)`; updating status produces `ActionType=StatusChanged` with old/new JSON; `AuditEntry` EF config rejects Update/Delete (INV-601)
- [ ] T012 [M] [US-027] xUnit: `UpdateSystemConfigurationCommand` — validation (0%→rejected; 1%→accepted; critical ≤ warning→rejected); dept override created and retrieved; `PreviousValue` captured; audit entry generated

### Quality Gates — Bolt 7A

- [ ] T013-QG `dotnet build --warnaserror` → 0 warnings
- [ ] T014-QG `dotnet test` → 100% pass
- [ ] T015-QG Coverlet line ≥ 80% / branch ≥ 75%
- [ ] T016-QG `dotnet stryker --project ReportingAdmin.Infrastructure.csproj` → ≥ 70%
- [ ] T017-QG Report query P95: 1 year data → < 5s (k6 load test with 500-employee dataset)

---

## Bolt 7B — Additional Reports, User Management Commands & Gherkin Gap Fix

**Goal:** Approval time + coverage reports, all user management commands, Gherkin gap fix, step bodies.
**Duration:** 3 days · **Weight:** 4.0L equivalent

### Application — Additional Report Queries

- [ ] T018 [M] [US-024] `GetApprovalTimeReportQuery` + handler: Dapper; avg/median/min/max per approver (BR-108–111); business-day calculation; bottleneck flag > 5 days average (AC-024.5); escalated requests flagged separately
- [ ] T019 [M] [US-025] `GetCoverageReportQuery` + handler: Dapper reads `CAPACITY_SNAPSHOTS`; daily or weekly granularity (BR-113); threshold highlighting (BR-114); historical comparison same period last year if data available (BR-115)

### Application — User Management Commands

- [ ] T020 [M] [US-028] `ChangeEmployeeRoleCommand` + handler: updates `Employee.Role`; emits `ActionType=RoleChanged` audit entry with old/new role; `RequireAdministrator` auth
- [ ] T021 [M] [US-028] `DeactivateEmployeeCommand` + handler: sets `IsActive=false`; last-admin guard (BR-129) → reject if only active admin; emit audit
- [ ] T022 [M] [US-028] `AdminRevokeDelegationCommand` + handler: calls `Delegation.Revoke()`; emit audit; immediate effect

### Gherkin Gap Fix

- [ ] T023 [M] [US-024][US-025] Create `approval-time-report.feature` (AC-024.1–024.5 `@smoke` + regression) and `coverage-report.feature` (AC-025.1–025.4 `@smoke`)
- [ ] T024 [M] Admin query: `SearchEmployeesForAdminQuery` + handler (Dapper: search by name/email; filter by role, dept; includes active delegations)

### Application — Report Execution

- [ ] T025 [M] [US-023] `GenerateReportCommand` + handler: creates `ReportExecution`; async background task for large datasets; updates status on completion; stores `FileUrl` after Azure Blob upload

### BDD Step Definitions

- [ ] T026 [M] [P] Implement `ReportingAdminSteps.cs` body methods for `vacation-history-report.feature`, `audit-trail.feature`, `system-configuration.feature`, `user-role-management.feature`, and new `approval-time-report.feature` + `coverage-report.feature`

### Tests

- [ ] T027 [M] [US-028] xUnit: `DeactivateEmployeeCommand` — last-admin guard (rejects when only 1 active admin; BR-129); deactivated user retains historical data
- [ ] T028 [M] [US-023] xUnit + Testcontainers: `GetVacationHistoryReportQuery` — DM sees only their department (BR-103); admin sees all; max 2-year range (BR-107); < 5s for 1 year of data

### Quality Gates — Bolt 7B

- [ ] T029-QG `dotnet build --warnaserror` → 0 warnings
- [ ] T030-QG `dotnet test` → 100% pass (including new Gherkin gap scenarios)
- [ ] T031-QG Coverlet line ≥ 80% / branch ≥ 75%
- [ ] T032-QG Audit search P95: < 2s for 1M entries (k6 with synthetic dataset)

---

## Bolt 7C — Report Export (CSV/Excel/PDF), Admin Vue SPA & E2E

**Goal:** File export generation, Azure Blob upload, all admin frontend views, Playwright smoke.
**Duration:** 3 days · **Weight:** 4.5L equivalent

### Infrastructure — Report Export

- [ ] T033 [L] [US-023] `CsvReportGenerator` (CsvHelper), `ExcelReportGenerator` (ClosedXML), `PdfReportGenerator` (QuestPDF — streaming; max 10,000 rows; paginate if exceeded); `ReportStorageService` — uploads to Azure Blob Storage, returns SAS URL (24h TTL; BR from missing spec)

### API

- [ ] T034 [M] `ReportEndpoints` (5 routes): `GET /api/reports/vacation-history`, `GET /api/reports/approval-time`, `GET /api/reports/coverage`, `POST /api/reports/export` (async; returns `ReportExecutionId`), `GET /api/reports/export/{executionId}`
- [ ] T035 [M] `AuditEndpoints` (2 routes): `GET /api/audit`, `POST /api/audit/export` — `RequireAdminOrAuditor`
- [ ] T036 [M] `AdminEndpoints` (7 routes): config CRUD, user search/role-change/deactivate, delegation list + revoke — `RequireAdministrator`

### Frontend

- [ ] T037 [M] [US-023] Vue: `reportsStore.ts` + `VacationHistoryReportView.vue` + `ReportFilters.vue` + `ReportTable.vue` (sortable columns, paginated) + `ExportButtons.vue` (polls `/api/reports/export/{id}` until completed; AC-023.3)
- [ ] T038 [M] [US-026] Vue: `AuditTrailView.vue` + `AuditTrailTable.vue` (search by user/date/action; reverse-chronological; "7-year retention" indicator)
- [ ] T039 [M] [US-027] Vue: `SystemConfigView.vue` + `ConfigTable.vue` (inline numeric edit; validation; dept override rows; confirmation on save; AC-027.5 change effect immediate)
- [ ] T040 [M] [US-028] Vue: `UserManagementView.vue` + `UserSearchTable.vue` (inline role dropdown; deactivate with confirm; greyed-out inactive rows; last-admin guard error; AC-028.5)

### Tests

- [ ] T041 [M] Vitest: `ConfigTable` inline-edit validation (threshold bounds); `ExportButtons` polls and downloads; `UserSearchTable` role dropdown + deactivate confirmation
- [ ] T042 [S] Reqnroll: all `@smoke` in all 6 `.feature` files (including gap-fix features)

### Quality Gates — Bolt 7C

- [ ] T043-QG `dotnet format` / `eslint` → 0 errors
- [ ] T044-QG `dotnet test` + `npm test` → 100% pass
- [ ] T045-QG Coverlet BE ≥ 80%; Vitest FE ≥ 80%
- [ ] T046-QG-E2E Playwright `@smoke`: `reporting-admin.spec.ts` → 0 failures (DM generates report; admin changes threshold; admin views audit; admin searches user)
- [ ] T047-QG Lighthouse CI: admin panel performance score ≥ 90
- [ ] T048-QG NetArchTest → all rules pass
- [ ] T049-QG SAST → 0 Critical
- [ ] T050-QG Azure Blob SAS URL: security review (time-limited, scoped to single execution)
