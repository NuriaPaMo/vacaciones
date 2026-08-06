# Feature: Active Directory Integration

## Metadata

| Property   | Value                                          |
| ---------- | ---------------------------------------------- |
| Feature ID | F-004                                          |
| Issue      | gh#5                                           |
| Author     | Bolt Feature Agent                             |
| Created    | 2026-08-06                                     |
| Status     | Draft                                          |
| Priority   | P1                                             |
| Epic       | Vacation Management & Approval System          |
| Scenario   | backend-only                                   |
| Bolt       | Bolt 4 (Week 11-12)                            |

---

## Business Context

### Problem Statement

The system requires employee data, organizational hierarchy (departments, projects, managers), and
role assignments from Active Directory. Currently, no automated mechanism exists to keep the
vacation system in sync with the corporate directory, meaning employee changes (new hires,
departures, transfers) require manual updates.

### Business Value

- Automated nightly synchronization eliminates manual user management
- Accurate organizational hierarchy enables correct approval routing
- Employee lifecycle handled automatically (new hires, terminations, transfers)
- Single source of truth for employee-department-manager relationships
- Reduces admin overhead by 90%

### Target Users

| Persona            | Description                       | Goals                                              |
| ------------------ | --------------------------------- | -------------------------------------------------- |
| Administrator      | IT admin managing integrations    | Monitor sync health, troubleshoot failures         |
| System (Scheduler) | Background job                    | Execute nightly sync reliably                      |

---

## User Stories

### US-012: Nightly Employee Synchronization

**As the** system scheduler
**I want** to synchronize employee data from Active Directory every night
**So that** the vacation system always reflects the current organizational structure

**Priority**: P1
**Effort**: L
**Dependencies**: None (foundational integration)

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-012.1  | Given the scheduled time (2:00 AM), when the sync job starts, then it fetches all employees from AD via Microsoft Graph API | Functional   | @smoke |
| AC-012.2  | Given new employees in AD, when synced, then they are created in the system with status Active     | Functional   | @smoke |
| AC-012.3  | Given an employee removed from AD, when synced, then they are marked as Inactive (soft delete) in the system | Functional   | —      |
| AC-012.4  | Given an employee whose department changed in AD, when synced, then the department assignment is updated | Functional   | —      |
| AC-012.5  | Given an employee whose manager changed in AD, when synced, then the manager relationship is updated | Functional   | —      |
| AC-012.6  | Given the sync job completes, then a summary log is written: total processed, created, updated, deactivated, errors | Functional   | @smoke |
| AC-012.7  | Given sync errors (API timeouts, partial failures), when they occur, then failed records are retried (max 3 attempts) and errors logged | Functional   | —      |
| AC-012.8  | Given the sync job, then it must complete within 30 minutes for 500 employees                      | Non-Functional | —     |

#### Business Rules

- BR-054: Sync runs nightly at 2:00 AM (configurable)
- BR-055: Read-only integration (no writes to AD)
- BR-056: Soft-delete only: employees are deactivated, never hard-deleted (audit trail)
- BR-057: Department and manager assignments update immediately on sync
- BR-058: New employees default to "Employee" role; PM/DM roles assigned manually or via AD group

---

### US-013: Organizational Hierarchy Sync

**As the** system scheduler
**I want** to synchronize the organizational hierarchy (departments, projects, manager assignments)
**So that** the approval workflow routes correctly based on current structure

**Priority**: P1
**Effort**: M
**Dependencies**: US-012

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-013.1  | Given AD data, when synced, then departments are created/updated based on the "department" attribute | Functional   | @smoke |
| AC-013.2  | Given AD manager relationships, when synced, then project manager assignments are derived from "manager" attributes | Functional   | —      |
| AC-013.3  | Given the hierarchy, when an employee moves to a new department, then their pending requests remain with the original approvers | Functional   | —      |
| AC-013.4  | Given a new department in AD, when synced, then it is automatically created in the system          | Functional   | —      |
| AC-013.5  | Given an empty department (all employees removed), when synced, then the department is marked inactive but not deleted | Functional   | —      |

#### Business Rules

- BR-059: Organizational structure has single level: Department (per RFP RT-002)
- BR-060: Projects are derived from AD groups or managed manually (configurable)
- BR-061: Manager-employee relationships are derived from AD "manager" attribute
- BR-062: Department manager is the user with the highest-level manager attribute pointing to them
- BR-063: Hierarchy changes do not affect in-progress approval workflows

---

### US-014: Manual Sync Trigger

**As an** administrator
**I want** to manually trigger an AD synchronization
**So that** I can immediately reflect organizational changes without waiting for the nightly job

**Priority**: P2
**Effort**: S
**Dependencies**: US-012

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-014.1  | Given an authenticated administrator, when they click "Sync Now", then an AD sync is triggered immediately | Functional   | @smoke |
| AC-014.2  | Given a manual sync, when it completes, then the admin sees a summary: processed, created, updated, deactivated, errors | Functional   | —      |
| AC-014.3  | Given a sync already in progress, when the admin clicks "Sync Now", then the system prevents duplicate runs with a message | Functional   | —      |
| AC-014.4  | Given a manual sync, when triggered, then it uses the same logic as the nightly sync               | Functional   | —      |

#### Business Rules

- BR-064: Only administrators can trigger manual sync
- BR-065: Concurrent sync prevention (mutex/lock)
- BR-066: Manual sync produces the same audit log as scheduled sync
- BR-067: Rate limit: maximum 1 manual sync per hour

---

### US-015: Sync Monitoring & Alerting

**As an** administrator
**I want** to monitor AD sync health and receive alerts on failures
**So that** I can quickly detect and resolve synchronization issues

**Priority**: P2
**Effort**: S
**Dependencies**: US-012

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-015.1  | Given the admin panel, when navigating to "Integration Health", then the last sync status is displayed (success/failure, timestamp, counts) | Functional   | @smoke |
| AC-015.2  | Given a sync failure, when it occurs, then an alert email is sent to administrators                | Functional   | —      |
| AC-015.3  | Given the sync history, when viewed, then the last 30 days of sync results are available with details | Functional   | —      |
| AC-015.4  | Given a sync with partial failures, when viewed, then the specific failed records are listed for troubleshooting | Functional   | —      |

#### Business Rules

- BR-068: Sync history retained for 90 days
- BR-069: Alert threshold: any sync with > 5% error rate triggers admin notification
- BR-070: Health endpoint exposes sync status for Azure Monitor integration

---

## Non-Functional Requirements

### Performance

| Metric            | Target     | Measurement                           |
| ----------------- | ---------- | ------------------------------------- |
| Full Sync Time    | < 30 min   | 500 employees from AD                 |
| Delta Processing  | < 100 ms   | Per employee record                   |
| Manual Sync API   | < 5 s      | Trigger response (async job start)    |

### Security

- [x] Authentication: Managed Identity for AD access (no secrets in code)
- [x] Authorization: Only admin role can trigger manual sync
- [x] Data: Employee data encrypted at rest
- [x] Audit: All sync operations logged with timestamps
- [x] GDPR: Only sync necessary PII fields (name, email, department, manager)

### Scalability

- Current: 500 employees
- 5-year projection: 1,000 employees
- Sync must scale linearly with employee count

### Availability

- Nightly job: must complete before ServiceNow export (4:00 AM)
- Retry logic: 3 attempts with exponential backoff
- Job locking: prevent concurrent execution

---

## Data Requirements

### New Entities

| Entity          | Description                          | Key Fields                                                    |
| --------------- | ------------------------------------ | ------------------------------------------------------------- |
| SyncJob         | Record of each sync execution        | Id, StartedAt, CompletedAt, Status, TotalProcessed, Created, Updated, Deactivated, Errors |
| SyncError       | Individual record sync failures      | Id, SyncJobId, EmployeeExternalId, ErrorMessage, RetryCount   |

### Modified Entities

| Entity          | Changes                                | Impact                             |
| --------------- | -------------------------------------- | ---------------------------------- |
| Employee        | Add: ExternalId, LastSyncedAt, Source  | Link to AD identity                |
| Department      | Add: ExternalId, LastSyncedAt          | Link to AD department              |

---

## Integration Points

| System            | Direction | Protocol              | Purpose                              |
| ----------------- | --------- | --------------------- | ------------------------------------ |
| Microsoft Graph   | Inbound   | REST API (Graph SDK)  | Fetch employees, departments, managers |
| Azure Service Bus | Internal  | Message queue         | Trigger manual sync async            |
| Azure Monitor     | Outbound  | OTel                  | Sync health metrics and alerts       |

---

## Out of Scope

- Writing data back to Active Directory
- Real-time sync (event-driven from AD changes)
- Multi-forest AD support
- Guest/external user synchronization
- Azure AD B2B/B2C scenarios

## Dependencies

- Microsoft Graph API access with appropriate permissions (User.Read.All, Directory.Read.All)
- Managed Identity configured for the Container App
- Azure AD tenant with users and organizational structure populated

## Open Questions

- Q-010: Is the "project" concept available in AD (via groups) or must it be managed manually?
- Q-011: How are "Department Managers" identified in AD? (title? manager chain? AD group?)
- Q-012: Should terminated employees' historical vacation data be preserved?

---

## Next Steps

> Spec generated in `specs/004-active-directory-integration/`. Scenario: **backend-only**.
>
> No mockups needed (backend-only scenario).
>
> Recommended next:
>
> 1. → `bolt-plan` + `bolt-gherkin` (in parallel).
> 2. Clarify Q-010 through Q-012 with stakeholders via `bolt-clarify`.
