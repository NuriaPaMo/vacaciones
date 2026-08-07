# Technical Plan — F-007: Reporting & Administration

## Metadata

| Property          | Value                                               |
| ----------------- | --------------------------------------------------- |
| Feature           | F-007 — Reporting & Administration                  |
| Scenario          | Fullstack (backend + frontend + cloud-platform)     |
| Bounded Context   | ReportingAdmin (Supporting Domain)                  |
| Bolt              | Bolt 7 — Week 17–18                                 |
| Issue             | gh#8                                                |
| Author            | Bolt Plan Agent                                     |
| Created           | 2026-08-07                                          |
| Status            | Draft                                               |
| Dependencies      | F-001 – F-006 complete (all data sources available) |

---

## Executive Summary

F-007 delivers **three predefined reports** (vacation history, approval time, coverage), a
**complete 7-year audit trail**, a **system configuration admin panel**, and **user/role
management**. The audit log is populated automatically by an EF Core `SaveChangesInterceptor`
that captures every state change across all bounded contexts. Reports use Dapper read models
and are exported to Azure Blob Storage (CSV/Excel/PDF). The admin panel is the gateway for
managing capacity thresholds, escalation rules, and email templates.

---

## Architecture Context

| Concern | Decision |
|---------|----------|
| Module | `src/Modules/ReportingAdmin/` |
| Audit | EF Core `SaveChangesInterceptor` — registered globally; writes `AuditEntry` in same transaction |
| Reports | Dapper read models — Cosmos or SQL read side; no EF Core for reports |
| Export | `ClosedXML` (Excel) + `QuestPDF` (PDF) + `CsvHelper` (CSV); files stored in Azure Blob |
| Authorization | Reports: DM + Admin; Audit: Admin + Auditor; Config: Admin only |
| Frontend | Vue 3: reports page, admin panel, audit log viewer, user management |

---

## Bolt Breakdown

| Bolt | Scope | Focus | Duration |
|------|-------|-------|----------|
| **7A** | Backend | AuditInterceptor + SystemConfiguration + CQRS report queries | 4 days |
| **7B** | Backend + Frontend | Report export (CSV/Excel/PDF) + Admin panel UI + User management UI | 4 days |

---

## Bolt 7A — Audit, Config & Report Queries

### Module Structure

```
src/Modules/ReportingAdmin/
  ├── Domain/
  │   ├── AuditEntry.cs               ← Aggregate Root (immutable)
  │   ├── SystemConfiguration.cs      ← Aggregate Root
  │   ├── ReportExecution.cs          ← Aggregate Root
  │   └── ValueObjects/
  │       ├── AuditEntryId.cs
  │       ├── AuditActionType.cs      ← 15 action types
  │       ├── AuditSource.cs          ← UserAction | System | BackgroundJob | Integration
  │       ├── ConfigScope.cs          ← Global | Department
  │       ├── ReportType.cs
  │       └── ReportFormat.cs         ← Csv | Excel | Pdf
  ├── Application/
  │   ├── Commands/
  │   │   ├── UpdateSystemConfiguration/
  │   │   ├── ChangeEmployeeRole/
  │   │   ├── DeactivateEmployee/
  │   │   ├── AdminRevokeDelegation/
  │   │   └── GenerateReport/
  │   └── Queries/
  │       ├── GetVacationHistoryReport/
  │       ├── GetApprovalTimeReport/
  │       ├── GetCoverageReport/
  │       ├── GetAuditTrail/
  │       ├── GetSystemConfigurations/
  │       └── SearchEmployeesForAdmin/
  ├── Infrastructure/
  │   ├── Audit/
  │   │   └── AuditInterceptor.cs     ← SaveChangesInterceptor
  │   ├── Reports/
  │   │   ├── CsvReportGenerator.cs   ← CsvHelper
  │   │   ├── ExcelReportGenerator.cs ← ClosedXML
  │   │   ├── PdfReportGenerator.cs   ← QuestPDF
  │   │   └── ReportStorageService.cs ← Azure Blob Storage
  │   ├── Persistence/
  │   │   ├── AuditEntryRepository.cs ← append-only
  │   │   ├── SystemConfigRepository.cs
  │   │   └── ReportExecutionRepository.cs
  │   └── ReadModels/
  │       ├── VacationHistoryReadModel.cs   ← Dapper
  │       ├── ApprovalTimeReadModel.cs      ← Dapper
  │       └── CoverageReadModel.cs          ← Dapper
  └── Api/
      ├── ReportEndpoints.cs
      ├── AuditEndpoints.cs
      └── AdminEndpoints.cs
```

### AuditInterceptor — Core Implementation

```csharp
public class AuditInterceptor : SaveChangesInterceptor
{
    public override async ValueTask<InterceptionResult<int>> SavingChangesAsync(
        DbContextEventData eventData, InterceptionResult<int> result, CancellationToken ct)
    {
        var entries = eventData.Context!.ChangeTracker.Entries()
            .Where(e => e.State is Added or Modified or Deleted)
            .ToList();

        var auditEntries = entries
            .Select(BuildAuditEntry)
            .Where(ae => ae is not null)
            .ToList();

        if (auditEntries.Any())
            eventData.Context.Set<AuditEntry>().AddRange(auditEntries!);

        return await base.SavingChangesAsync(eventData, result, ct);
    }

    private AuditEntry? BuildAuditEntry(EntityEntry entry)
    {
        // Exclude AuditEntry itself to prevent infinite recursion
        if (entry.Entity is AuditEntry) return null;

        return new AuditEntry(
            Id: AuditEntryId.New(),
            Timestamp: DateTime.UtcNow,      // BR-120: UTC
            UserId: _currentUser.EmployeeId,
            UserDisplayName: _currentUser.DisplayName,
            ActionType: MapActionType(entry.State),
            EntityType: entry.Entity.GetType().Name,
            EntityId: GetEntityId(entry),
            OldValuesJson: entry.State == Modified ? SerializeOldValues(entry) : null,
            NewValuesJson: entry.State == Deleted ? null : SerializeNewValues(entry),
            Source: _auditContext.Source
        );
    }
}
```

**PII redaction in audit JSON** — fields marked with `[AuditRedact]` attribute are replaced with `"***"` before serialization.

### Implementation Checklist — Bolt 7A

- [ ] `AuditInterceptor` — registered globally in `DbContextOptionsBuilder`; captures all entity changes (INV-601–604)
- [ ] `AuditEntry` is append-only: no EF Update/Delete config for `AUDIT_ENTRIES` table; only Insert allowed
- [ ] `SystemConfiguration` aggregate — INV-610–614; `Update(newValue, updatedBy)` method captures `PreviousValue`
- [ ] `SystemConfigRepository.GetEffectiveValueAsync(key, deptId)` — dept override > global (BR-124)
- [ ] EF Core migration `M008_CreateReportingAdminTables` + `M009_SeedSystemConfigurations` (default threshold values)
- [ ] Dapper read models — `VacationHistoryReadModel.GetAsync(filters)`: joins VR + Employee + Department + ApprovalStep
- [ ] Dapper read models — `ApprovalTimeReadModel.GetAsync()`: calculates avg/median/min/max per approver (BR-108–111)
- [ ] Dapper read models — `CoverageReadModel.GetAsync()`: reads from `CAPACITY_SNAPSHOTS` table (BR-112–115)
- [ ] `GetAuditTrailQuery` handler — Dapper; paginated; filterable by user/date/action/entity (AC-026.3)
- [ ] Audit log indexes: `IX_AE_Timestamp`, `IX_AE_UserId_Timestamp`, `IX_AE_EntityType_EntityId` (performance for AC-026: < 2s)

---

## Bolt 7B — Report Export & Admin UI

### Report Export Implementation

```csharp
public class GenerateReportHandler : ICommandHandler<GenerateReportCommand, ReportExecutionId>
{
    public async Task<ReportExecutionId> HandleAsync(GenerateReportCommand cmd, CancellationToken ct)
    {
        var execution = ReportExecution.Create(cmd.ReportType, cmd.Format, cmd.ParametersJson, cmd.RequestedBy);
        await _repo.SaveAsync(execution, ct);

        // Execute async (background task) for large reports to avoid API timeout
        _ = Task.Run(() => ExecuteReportAsync(execution, ct), ct);

        return execution.Id;
    }

    private async Task ExecuteReportAsync(ReportExecution execution, CancellationToken ct)
    {
        var rows = await FetchReportDataAsync(execution.ReportType, execution.ParametersJson, ct);
        var fileBytes = execution.Format switch
        {
            ReportFormat.Csv   => _csvGen.Generate(rows),
            ReportFormat.Excel => _excelGen.Generate(rows),
            ReportFormat.Pdf   => _pdfGen.Generate(rows),
            _ => throw new ArgumentOutOfRangeException()
        };

        var url = await _storage.UploadAsync($"reports/{execution.Id}.{GetExtension(execution.Format)}", fileBytes, ct);
        execution.Complete(url, fileBytes.LongLength);
        await _repo.SaveAsync(execution, ct);
    }
}
```

### Backend — API Endpoints

**Reports**

| Method | Route | Handler | Auth |
|--------|-------|---------|------|
| `GET` | `/api/reports/vacation-history` | `GetVacationHistoryReportHandler` | DM + Admin |
| `GET` | `/api/reports/approval-time` | `GetApprovalTimeReportHandler` | DM + Admin |
| `GET` | `/api/reports/coverage` | `GetCoverageReportHandler` | DM + Admin |
| `POST` | `/api/reports/export` | `GenerateReportHandler` | DM + Admin |
| `GET` | `/api/reports/export/{executionId}` | `GetReportExecutionStatusHandler` | DM + Admin |

**Audit**

| Method | Route | Handler | Auth |
|--------|-------|---------|------|
| `GET` | `/api/audit` | `GetAuditTrailHandler` | Admin + Auditor |
| `POST` | `/api/audit/export` | `ExportAuditTrailHandler` | Admin + Auditor |

**Admin — Configuration**

| Method | Route | Handler | Auth |
|--------|-------|---------|------|
| `GET` | `/api/admin/config` | `GetSystemConfigurationsHandler` | Admin |
| `PUT` | `/api/admin/config/{key}` | `UpdateSystemConfigurationHandler` | Admin |

**Admin — User Management**

| Method | Route | Handler | Auth |
|--------|-------|---------|------|
| `GET` | `/api/admin/users` | `SearchEmployeesForAdminHandler` | Admin |
| `PATCH` | `/api/admin/users/{id}/role` | `ChangeEmployeeRoleHandler` | Admin |
| `DELETE` | `/api/admin/users/{id}` | `DeactivateEmployeeHandler` | Admin |
| `GET` | `/api/admin/delegations` | `GetAllDelegationsHandler` | Admin |
| `DELETE` | `/api/admin/delegations/{id}` | `AdminRevokeDelegationHandler` | Admin |

### Frontend Tasks — Vue 3 SPA

```
src/frontend/src/modules/reporting-admin/
  ├── views/
  │   ├── VacationHistoryReportView.vue   ← US-023
  │   ├── ApprovalTimeReportView.vue      ← US-024
  │   ├── CoverageReportView.vue          ← US-025
  │   ├── AuditTrailView.vue              ← US-026
  │   ├── SystemConfigView.vue            ← US-027
  │   └── UserManagementView.vue         ← US-028
  ├── components/
  │   ├── ReportFilters.vue
  │   ├── ReportTable.vue                 ← sortable, paginated
  │   ├── ExportButtons.vue               ← CSV / Excel / PDF triggers
  │   ├── ReportExportStatus.vue          ← polling for async export completion
  │   ├── AuditTrailTable.vue             ← search + filter by user/date/action
  │   ├── ConfigTable.vue                 ← inline edit for threshold values
  │   ├── UserSearchTable.vue             ← role badge + actions
  │   ├── RoleChangeModal.vue
  │   └── DelegationManagementTable.vue   ← admin view of all delegations
  ├── stores/
  │   ├── reportsStore.ts
  │   ├── auditStore.ts
  │   └── adminStore.ts
  └── api/
      ├── reportsApi.ts
      ├── auditApi.ts
      └── adminApi.ts
```

**Implementation checklist — Bolt 7B frontend**

- [ ] `VacationHistoryReportView` — filter panel: date range, dept, project, employee, status (AC-023.1)
- [ ] `ReportTable` — sortable columns; show employee, dates, days, status, approvers (AC-023.2)
- [ ] `ExportButtons` — trigger async export; poll `/api/reports/export/{id}` until completed; download link
- [ ] `AuditTrailView` — paginated table; filter by user, date range, action type (AC-026.3)
- [ ] `SystemConfigView` — inline edit per config key; shows global + per-dept overrides; validation (AC-027.2)
- [ ] Config change: confirmation dialog + immediate effect indicator (BR-122)
- [ ] `UserSearchTable` — search bar; role badge; deactivate action with confirmation (AC-028.1–3)
- [ ] `DelegationManagementTable` — admin revoke button (AC-028.5)
- [ ] Route guards: `requireAdmin` for config/user mgmt; `requireAdminOrAuditor` for audit; `requireDMOrAdmin` for reports
- [ ] Bottleneck highlight in `ApprovalTimeReportView` — red row when avg > 5 days (AC-024.5)

---

## Test Strategy

### Backend

| Type | Key Scenarios |
|------|---------------|
| Infrastructure | `AuditInterceptor` — adding a `VacationRequest` produces `AuditEntry` with `ActionType = Created` |
| Infrastructure | `AuditInterceptor` — updating status produces `ActionType = StatusChanged` with old/new JSON |
| Infrastructure | `AuditEntry` — EF config prevents Update/Delete operations |
| Application Unit | `UpdateSystemConfigurationHandler` — validation: threshold must be 1–100 |
| Application Unit | `ChangeEmployeeRoleHandler` — change audited with before/after role |
| Application Unit | `DeactivateEmployeeHandler` — last admin check (BR-129) |
| Application Unit | `GetVacationHistoryReportHandler` — DM sees only own department data (BR-103) |
| Integration | Dapper report query — 1 year of data returns in < 5s (NFR) |
| Integration | `GenerateReportHandler` — Excel file generated and uploaded to Blob |
| BDD | AC-023.1 `@smoke` — DM navigates to report, applies filters |
| BDD | AC-023.2 `@smoke` — report renders correct data |
| BDD | AC-026.1 `@smoke` — audit trail shows all user actions |
| BDD | AC-026.2 `@smoke` — each entry has timestamp, user, action, entity, old/new values |
| BDD | AC-027.1 `@smoke` — admin accesses config panel |
| BDD | AC-027.2 `@smoke` — threshold change takes effect immediately |
| BDD | AC-028.1 `@smoke` — admin searches and finds a user with their details |
| Performance | `/api/reports/vacation-history` — P95 < 5s for 1 year of data (k6) |
| Performance | `/api/audit` — P95 < 2s for 1M entries search (k6) |

### Frontend

| Type | Key Scenarios |
|------|---------------|
| Component | `ConfigTable` — edit validation: threshold 1–100, critical > warning |
| Component | `ExportButtons` — polls until export completes; shows progress |
| E2E | `@smoke` — DM generates vacation history report |
| E2E | `@smoke` — Admin changes capacity threshold; value saved immediately |
| E2E | `@smoke` — Admin views audit trail and searches by user |

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
| Report query P95 | < 5 s (1 year data) |
| Audit search P95 | < 2 s (1M entries) |

---

## Risks & Mitigations

| Risk | Prob | Impact | Mitigation |
|------|------|--------|------------|
| `AuditInterceptor` causes N+1 — every entity save generates audit entries | High | Medium | Batch audit entries in same `SaveChanges` call; no additional DB round-trips |
| PDF generation (QuestPDF) memory usage for large reports | Medium | Medium | Stream PDF; cap at 10,000 rows per PDF; paginate otherwise |
| Audit log grows faster than expected — query slows down | Low | Medium | Partition `AUDIT_ENTRIES` table by `Timestamp` year; add covering index |
| Report export SAS URL expires before user downloads | Low | Low | Set SAS URL TTL to 24 hours; regenerate on request |
| Admin deactivating last admin locks out system | Low | Critical | `DeactivateEmployeeHandler` checks admin count before proceeding (BR-129) |

---

## Dependencies

| Dependency | Type | Status |
|-----------|------|--------|
| F-001 – F-006 all deployed (data available for reports) | Hard | Blocks Bolt 7A report queries |
| Azure Blob Storage provisioned (Phase 4) | Hard | Required for report file export |
| `CAPACITY_SNAPSHOTS` table populated (F-003) | Hard | Required for coverage report |
| Notification templates seeded (F-006 Bolt 6A) | Soft | Required for template management in F-007 admin UI |
