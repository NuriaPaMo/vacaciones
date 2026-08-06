# Feature: Reporting & Administration

## Metadata

| Property   | Value                                          |
| ---------- | ---------------------------------------------- |
| Feature ID | F-007                                          |
| Issue      | gh#8                                           |
| Author     | Bolt Feature Agent                             |
| Created    | 2026-08-06                                     |
| Status     | Draft                                          |
| Priority   | P1                                             |
| Epic       | Vacation Management & Approval System          |
| Scenario   | fullstack (backend + frontend + cloud-platform) |
| Bolt       | Bolt 7 (Week 17-18)                            |

---

## Business Context

### Problem Statement

Managers need historical reports on vacation patterns, approval metrics, and coverage analysis for
strategic planning. Administrators need a configuration interface to manage system parameters,
thresholds, and user roles. There is no audit trail today, which is a compliance gap. The RFP
requires 7-year audit log retention and comprehensive reporting capabilities.

### Business Value

- Complete audit trail meets compliance requirements (7-year retention)
- Vacation history reports enable strategic workforce planning
- Approval time reports identify bottlenecks in the workflow
- Coverage reports support capacity planning for peak seasons
- Admin interface reduces dependency on developer support
- Self-service configuration empowers department managers

### Target Users

| Persona            | Description                       | Goals                                              |
| ------------------ | --------------------------------- | -------------------------------------------------- |
| Department Manager | Generates reports for executives  | Vacation patterns, coverage analysis, compliance   |
| Administrator      | System configuration management   | Manage thresholds, templates, roles, integrations  |
| Auditor            | Compliance verification           | Review complete history of all actions              |

---

## User Stories

### US-023: Vacation History Report

**As a** department manager
**I want** to generate a report of all vacations by employee, date range, and status
**So that** I can analyze vacation patterns and plan for coverage needs

**Priority**: P1
**Effort**: M
**Dependencies**: F-001, F-002 (vacation data with statuses)

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-023.1  | Given an authenticated DM, when they navigate to "Reports > Vacation History", then they can filter by: date range, department, project, employee, status | Functional   | @smoke |
| AC-023.2  | Given filter criteria, when the report is generated, then it shows: employee name, dates, total days, status, approvers | Functional   | @smoke |
| AC-023.3  | Given a generated report, when the user clicks "Export", then it downloads in CSV, Excel, or PDF format | Functional   | —      |
| AC-023.4  | Given the report, when filtered by "Approved" status, then only fully-approved vacations are shown | Functional   | —      |
| AC-023.5  | Given a DM, then the report only shows data for their department (not other departments)           | Functional   | —      |
| AC-023.6  | Given the report generation, then it must complete within 5 seconds for 1 year of data             | Non-Functional | —     |

#### Business Rules

- BR-103: DMs see only their department; admins see all departments
- BR-104: Report data includes all statuses (Pending, Approved, Rejected, Cancelled)
- BR-105: Date range defaults to current year
- BR-106: Export formats: CSV (data), Excel (formatted), PDF (printable)
- BR-107: Maximum report range: 2 years per query

---

### US-024: Approval Time Report

**As a** department manager
**I want** to see metrics on how long approvals take by approver and department
**So that** I can identify bottlenecks and improve the approval process

**Priority**: P2
**Effort**: M
**Dependencies**: F-002 (approval timestamps)

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-024.1  | Given the approval time report, when generated, then it shows average, median, min, and max approval time | Functional   | @smoke |
| AC-024.2  | Given the report, when grouped by approver, then each approver's metrics are shown                 | Functional   | —      |
| AC-024.3  | Given the report, when grouped by department, then department-level aggregate metrics are shown     | Functional   | —      |
| AC-024.4  | Given the report, when a date range is applied, then only approvals within that period are included | Functional   | —      |
| AC-024.5  | Given the report, when an approver has > 5 day average, then they are highlighted as a bottleneck  | Functional   | —      |

#### Business Rules

- BR-108: Approval time = difference between request submission and final approval (both levels)
- BR-109: Only completed approvals count (pending excluded)
- BR-110: Escalated requests are flagged separately in the report
- BR-111: Business days only for time calculations

---

### US-025: Coverage Report

**As a** department manager
**I want** to generate a report showing vacation coverage by period and department/project
**So that** I can plan for adequate staffing during high-demand periods

**Priority**: P2
**Effort**: M
**Dependencies**: F-003 (capacity data)

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-025.1  | Given the coverage report, when generated for a date range, then it shows daily/weekly coverage percentage per department/project | Functional   | @smoke |
| AC-025.2  | Given the report, when periods exceed the threshold (70%), then they are highlighted               | Functional   | —      |
| AC-025.3  | Given the report, when compared across departments/projects, then a comparative table is shown     | Functional   | —      |
| AC-025.4  | Given the report, when exported, then it includes charts/visualizations (PDF) or raw data (CSV/Excel) | Functional   | —      |

#### Business Rules

- BR-112: Coverage = (employees on vacation / total employees) × 100 per day
- BR-113: Report can aggregate by day or week
- BR-114: Threshold for highlighting is the same as configured for heat map (F-003)
- BR-115: Historical comparison: show same period last year (if data available)

---

### US-026: Audit Trail

**As an** auditor
**I want** to access a complete, searchable log of all system actions
**So that** I can verify compliance with vacation policies and regulations

**Priority**: P1
**Effort**: L
**Dependencies**: All features (all generate audit events)

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-026.1  | Given the audit trail, when accessed, then it shows all user actions: create, approve, reject, cancel, delegate, configure | Functional   | @smoke |
| AC-026.2  | Given an audit entry, then it includes: timestamp, user identity, action type, entity affected, before/after values | Functional   | @smoke |
| AC-026.3  | Given the audit trail, when searched by user, date range, or action type, then matching entries are returned | Functional   | —      |
| AC-026.4  | Given the audit trail, when exported, then it downloads in CSV or PDF format                       | Functional   | —      |
| AC-026.5  | Given system events (integrations, batch jobs), then they are also recorded in the audit trail     | Functional   | —      |
| AC-026.6  | Given audit log retention, then records are preserved for 7 years (per compliance requirement)      | Non-Functional | —     |

#### Business Rules

- BR-116: Audit log is append-only (no modifications or deletions)
- BR-117: Retention period: 7 years (per RFP requirement)
- BR-118: System events include: AD sync, ServiceNow export, escalation triggers
- BR-119: Audit trail access limited to administrators and designated auditors
- BR-120: Audit entries are timestamped in UTC

---

### US-027: System Configuration

**As an** administrator
**I want** to configure system parameters through an admin interface
**So that** I can manage the system without developer intervention

**Priority**: P1
**Effort**: M
**Dependencies**: None (standalone admin capability)

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-027.1  | Given an authenticated administrator, when they access the admin panel, then they can configure: capacity thresholds, escalation timeframes, and batch job schedules | Functional   | @smoke |
| AC-027.2  | Given threshold configuration, when the admin changes the critical threshold (e.g., 70% → 75%), then the new value applies to all future capacity calculations | Functional   | @smoke |
| AC-027.3  | Given escalation configuration, when the admin changes the reminder threshold (e.g., 3 days → 5 days), then new values apply to future escalation checks | Functional   | —      |
| AC-027.4  | Given notification template configuration, when the admin edits an email template, then future notifications use the updated template | Functional   | —      |
| AC-027.5  | Given any configuration change, then it is recorded in the audit trail with before/after values    | Functional   | —      |
| AC-027.6  | Given department-specific configuration, when the admin sets thresholds per department, then each department uses its own values | Functional   | —      |

#### Business Rules

- BR-121: Only administrators can access the configuration panel
- BR-122: Configuration changes take effect immediately (no restart required)
- BR-123: All configuration changes are audited
- BR-124: Department-specific settings override global defaults
- BR-125: Configuration has validation rules (e.g., threshold must be 1-100%)

---

### US-028: User & Role Management

**As an** administrator
**I want** to manage user roles and delegation assignments
**So that** I can control who has approval authority and system access

**Priority**: P1
**Effort**: S
**Dependencies**: F-004 (users from AD), F-002 (delegation)

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-028.1  | Given the user management panel, when an admin searches for a user, then they can view their: role, department, projects, active delegations | Functional   | @smoke |
| AC-028.2  | Given a user, when the admin changes their role (e.g., Employee → Project Manager), then the new role takes effect immediately | Functional   | —      |
| AC-028.3  | Given a user, when the admin deactivates them, then they can no longer login or submit requests    | Functional   | —      |
| AC-028.4  | Given active delegations, when the admin views the delegation list, then all current delegations are shown with delegator, delegate, scope, and dates | Functional   | —      |
| AC-028.5  | Given a delegation, when the admin revokes it, then the delegate immediately loses approval authority | Functional   | —      |

#### Business Rules

- BR-126: Roles: Employee, Project Manager, Department Manager, Administrator
- BR-127: Role changes are audited
- BR-128: Deactivated users retain historical data (soft delete)
- BR-129: Admin cannot deactivate the last administrator
- BR-130: Users synced from AD can be overridden for role assignment

---

## Non-Functional Requirements

### Performance

| Metric              | Target    | Measurement                           |
| ------------------- | --------- | ------------------------------------- |
| Report Generation   | < 5 s     | 1 year of data, 500 employees        |
| Audit Trail Search  | < 2 s     | Search within 1 million entries       |
| Export (CSV)        | < 10 s    | 10,000 rows                           |
| Export (PDF)        | < 15 s    | Formatted report with charts          |
| Admin Page Load     | < 2 s     | Configuration panel                   |

### Security

- [x] Authentication required (Entra ID)
- [x] Authorization: Reports → DM + Admin; Audit → Admin + Auditor; Config → Admin only
- [x] Audit log is immutable (append-only)
- [x] Exported reports respect data visibility (DM sees only their department)
- [x] Configuration changes require admin role confirmation

### Scalability

- Audit log growth: ~10,000 entries/month (500 users × 20 actions each)
- 7-year retention: ~840,000 audit entries
- Report queries must be optimized for large datasets (indexing, pagination)

### Availability

- Target uptime: 99.5%
- Audit log writes must never fail (async with retry)
- Report generation can be queued during high load

---

## Data Requirements

### New Entities

| Entity              | Description                          | Key Fields                                                     |
| ------------------- | ------------------------------------ | -------------------------------------------------------------- |
| AuditEntry          | Immutable action log                 | Id, Timestamp, UserId, ActionType, EntityType, EntityId, OldValues (JSON), NewValues (JSON) |
| SystemConfiguration | Global and per-department settings   | Id, Key, Value, Scope (Global/Department), DepartmentId, UpdatedBy, UpdatedAt |
| ReportExecution     | Record of generated reports          | Id, ReportType, Parameters (JSON), GeneratedBy, GeneratedAt, FileUrl |

### Modified Entities

_None (reads from existing entities)_

---

## Integration Points

| System            | Direction | Protocol        | Purpose                              |
| ----------------- | --------- | --------------- | ------------------------------------ |
| Azure SQL         | Inbound   | EF Core/Dapper  | Read vacation, approval, employee data for reports |
| Azure Blob Storage| Outbound  | SDK             | Store exported report files          |
| Azure Monitor     | Outbound  | OTel            | Report generation metrics            |
| Frontend          | Outbound  | REST API        | Admin panel, reports, audit trail UI |

---

## Out of Scope

- Advanced analytics (ML-based predictions)
- Real-time reporting dashboards (covered in F-003 dashboard)
- Custom report builder (only predefined reports in Phase 1)
- Data warehouse / OLAP cube
- External reporting tools integration (Power BI)

## Dependencies

- All previous features (F-001 through F-006) for data availability
- Azure Blob Storage for exported report files
- Sufficient Azure SQL capacity for 7-year audit log retention

## Open Questions

- Q-021: Should audit log be stored in a separate database for performance isolation?
- Q-022: Are there specific report templates/formats required by compliance?
- Q-023: Should the admin be able to create custom reports or only use predefined ones?
- Q-024: Is there a specific retention policy beyond 7 years (archival to cold storage)?

---

## Next Steps

> Spec generated in `specs/007-reporting-administration/`. Scenario: **fullstack**.
>
> Recommended next:
>
> 1. Invoke `bolt-mockup` (mode: generate) for admin panel and reporting views.
> 2. Then → `bolt-plan` + `bolt-gherkin` (in parallel).
