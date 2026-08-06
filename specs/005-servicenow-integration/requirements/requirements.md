# Feature: ServiceNow Integration

## Metadata

| Property   | Value                                          |
| ---------- | ---------------------------------------------- |
| Feature ID | F-005                                          |
| Issue      | gh#6                                           |
| Author     | Bolt Feature Agent                             |
| Created    | 2026-08-06                                     |
| Status     | Draft                                          |
| Priority   | P1                                             |
| Epic       | Vacation Management & Approval System          |
| Scenario   | backend-only                                   |
| Bolt       | Bolt 5 (Week 13-14)                            |

---

## Business Context

### Problem Statement

Approved vacations must be reflected in ServiceNow (the corporate ITSM tool) for resource planning
and compliance. Currently, this is done manually by administrators, leading to data entry errors,
delays, and incomplete records. The RFP mandates that only fully-approved vacations (both project
and department level) are exported nightly.

### Business Value

- Eliminate manual ServiceNow data entry (100% automated)
- Ensure only fully-approved vacations reach ServiceNow (data integrity)
- Delta synchronization minimizes API calls and processing time
- Complete audit trail of all exported records
- Error handling with retry logic prevents data loss

### Target Users

| Persona            | Description                       | Goals                                              |
| ------------------ | --------------------------------- | -------------------------------------------------- |
| Administrator      | IT admin monitoring integrations  | Verify export success, troubleshoot failures       |
| System (Scheduler) | Background job                    | Execute nightly export reliably                    |

---

## User Stories

### US-016: Nightly Vacation Export to ServiceNow

**As the** system scheduler
**I want** to export all newly-approved vacations to ServiceNow every night
**So that** the corporate ITSM system reflects current vacation records

**Priority**: P1
**Effort**: L
**Dependencies**: F-001, F-002 (only Approved requests exported)

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-016.1  | Given the scheduled time (4:00 AM), when the export job starts, then it queries all Approved requests not yet exported | Functional   | @smoke |
| AC-016.2  | Given approved requests, when exported, then each record is POSTed to ServiceNow Table API with correct field mapping | Functional   | @smoke |
| AC-016.3  | Given a successful export, when completed, then the request is marked as "Exported" with timestamp | Functional   | @smoke |
| AC-016.4  | Given a cancelled request that was previously exported, when detected, then a DELETE/update is sent to ServiceNow to remove it | Functional   | —      |
| AC-016.5  | Given an API error from ServiceNow, when it occurs, then the failed record is retried up to 3 times with exponential backoff | Functional   | —      |
| AC-016.6  | Given the export job completes, then a summary log is written: total exported, updated, deleted, failed | Functional   | —      |
| AC-016.7  | Given the export job, then it must complete within 15 minutes for a typical batch (50 records)      | Non-Functional | —     |

#### Business Rules

- BR-071: Only requests with status = "Approved" (both levels) are eligible for export
- BR-072: Delta sync: only export new or changed records since last successful export
- BR-073: Cancelled requests that were previously exported trigger a removal in ServiceNow
- BR-074: Export runs after AD sync (4:00 AM - 6:00 AM window)
- BR-075: Failed records do not block the rest of the batch

---

### US-017: Employee Data Import from ServiceNow

**As the** system scheduler
**I want** to import employee vacation balance information from ServiceNow
**So that** employees can see their remaining vacation days when submitting requests

**Priority**: P3
**Effort**: M
**Dependencies**: US-016, F-004 (employee entity must exist)

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-017.1  | Given the nightly import job, when it runs, then vacation balance data is fetched from ServiceNow for all active employees | Functional   | @smoke |
| AC-017.2  | Given imported balance data, when stored, then the employee record is updated with total days, used days, and remaining days | Functional   | —      |
| AC-017.3  | Given import errors, when they occur, then failed records are logged and retried (max 3 attempts)  | Functional   | —      |
| AC-017.4  | Given the import completes, then a summary log is written: total processed, updated, errors        | Functional   | —      |

#### Business Rules

- BR-076: Import runs after export (6:00 AM - 7:00 AM window)
- BR-077: Balance data is informational only (validation against balance is optional in Phase 1)
- BR-078: If ServiceNow is unavailable, the system continues to function with stale balance data
- BR-079: Balance displayed to employees with a "last updated" timestamp

---

### US-018: Export Monitoring & Error Recovery

**As an** administrator
**I want** to monitor ServiceNow export health and manually retry failed records
**So that** I can ensure data consistency between systems

**Priority**: P2
**Effort**: S
**Dependencies**: US-016

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-018.1  | Given the admin panel, when navigating to "ServiceNow Integration", then the last export status is shown (success/failure, counts, timestamp) | Functional   | @smoke |
| AC-018.2  | Given failed export records, when viewed, then the admin sees: employee name, dates, error message, retry count | Functional   | —      |
| AC-018.3  | Given a failed record, when the admin clicks "Retry", then the system attempts to export that specific record again | Functional   | —      |
| AC-018.4  | Given persistent failures (>3 retries), when they exist, then an alert email is sent to administrators | Functional   | —      |
| AC-018.5  | Given the export history, when viewed, then the last 30 days of export results are available       | Functional   | —      |

#### Business Rules

- BR-080: Export history retained for 90 days
- BR-081: Alert threshold: any export with > 5% error rate triggers admin notification
- BR-082: Manual retry resets the retry counter for that record
- BR-083: Persistent failures (after manual retry) are escalated to IT support

---

## Non-Functional Requirements

### Performance

| Metric            | Target     | Measurement                           |
| ----------------- | ---------- | ------------------------------------- |
| Export Batch      | < 15 min   | 50 records typical batch              |
| Per-Record Export | < 2 s      | Single ServiceNow API call            |
| Import Batch      | < 10 min   | 500 employee balances                 |

### Security

- [x] Authentication: OAuth 2.0 or API key for ServiceNow (stored in Key Vault)
- [x] Authorization: Only system account can execute exports
- [x] Data: Only approved vacation data shared (no PII beyond what's required)
- [x] Audit: All export/import operations logged with timestamps
- [x] GDPR: Data minimization — only export necessary fields

### Scalability

- Current: 50-100 records per nightly batch (typical)
- Peak: 200 records per batch (summer approval surge)
- 5-year: 200-400 records per batch

### Availability

- Nightly job must complete before business hours (before 7:00 AM)
- Retry logic with exponential backoff (1s, 5s, 30s)
- Circuit breaker: if ServiceNow is down, skip export and alert admin

---

## Data Requirements

### New Entities

| Entity            | Description                          | Key Fields                                                          |
| ----------------- | ------------------------------------ | ------------------------------------------------------------------- |
| ExportJob         | Record of each export execution      | Id, StartedAt, CompletedAt, Status, TotalExported, Updated, Deleted, Errors |
| ExportRecord      | Individual record export status      | Id, ExportJobId, RequestId, ServiceNowRecordId, Status, ExportedAt, ErrorMessage, RetryCount |

### Modified Entities

| Entity          | Changes                                  | Impact                             |
| --------------- | ---------------------------------------- | ---------------------------------- |
| VacationRequest | Add: IsExported, ExportedAt, ServiceNowId | Track export status               |
| Employee        | Add: VacationBalance, BalanceUpdatedAt    | Store imported balance (Phase 2)   |

---

## Integration Points

| System            | Direction | Protocol              | Purpose                              |
| ----------------- | --------- | --------------------- | ------------------------------------ |
| ServiceNow        | Outbound  | REST API (Table API)  | Export approved vacations            |
| ServiceNow        | Inbound   | REST API (Table API)  | Import vacation balance (Phase 2)    |
| Azure Key Vault   | Inbound   | Managed Identity      | Retrieve ServiceNow credentials      |
| Azure Service Bus | Internal  | Message queue         | Trigger manual retry async           |
| Azure Monitor     | Outbound  | OTel                  | Export health metrics and alerts     |

---

## Out of Scope

- Real-time synchronization with ServiceNow
- Bi-directional sync (ServiceNow → vacation system for approvals)
- ServiceNow workflow triggers
- ServiceNow reporting integration
- Multi-instance ServiceNow support

## Dependencies

- ServiceNow instance with Table API access enabled
- ServiceNow API credentials (OAuth 2.0 or API key)
- ServiceNow sandbox environment for testing
- Azure Key Vault for credential storage
- F-001 + F-002: Approved vacation requests must exist

## Open Questions

- Q-013: What is the exact ServiceNow table name and field mapping for vacation records?
- Q-014: Does ServiceNow have rate limits that affect batch export?
- Q-015: Should the system handle ServiceNow downtime by queuing exports for later?
- Q-016: Is vacation balance import critical for Phase 1 or can it be deferred to Phase 2?

---

## Next Steps

> Spec generated in `specs/005-servicenow-integration/`. Scenario: **backend-only**.
>
> No mockups needed (backend-only scenario, admin UI only).
>
> Recommended next:
>
> 1. → `bolt-plan` + `bolt-gherkin` (in parallel).
> 2. Clarify Q-013 through Q-016 with ServiceNow team via `bolt-clarify`.
