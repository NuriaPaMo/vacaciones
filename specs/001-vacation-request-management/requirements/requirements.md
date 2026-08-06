# Feature: Vacation Request Management

## Metadata

| Property   | Value                                          |
| ---------- | ---------------------------------------------- |
| Feature ID | F-001                                          |
| Issue      | gh#2                                           |
| Author     | Bolt Feature Agent                             |
| Created    | 2026-08-06                                     |
| Status     | Draft                                          |
| Priority   | P1                                             |
| Epic       | Vacation Management & Approval System          |
| Scenario   | fullstack (backend + frontend + cloud-platform) |
| Bolt       | Bolt 1 (Week 5-6)                              |

---

## Business Context

### Problem Statement

Employees currently submit vacation requests via email, leading to lost requests, no status
visibility, slow processing, and no audit trail. There is no centralized system to manage the
lifecycle of a vacation request from submission through approval to completion.

### Business Value

- Centralize all vacation requests in a single system
- Provide real-time status visibility to employees
- Enable self-service cancellation
- Create the foundation domain model for the entire vacation management system
- Reduce approval cycle time from 5-7 days to < 48 hours

### Target Users

| Persona            | Description                    | Goals                                         |
| ------------------ | ------------------------------ | --------------------------------------------- |
| Employee (Ana)     | Software Developer, tech-savvy | Submit requests quickly, track status          |
| Project Manager    | Senior PM, moderate tech       | View team requests as foundation for approval  |
| Department Manager | Director, moderate tech        | View department requests overview              |

---

## User Stories

### US-001: Submit Vacation Request

**As an** employee
**I want** to submit a vacation request with start and end dates
**So that** I can formally request time off through the system

**Priority**: P1
**Effort**: L
**Dependencies**: None (core entity)

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-001.1  | Given an authenticated employee, when they select start and end dates and submit, then a vacation request is created with status "Pending" | Functional   | @smoke |
| AC-001.2  | Given a request submission, when the system processes it, then the total business days are calculated automatically (excluding weekends) | Functional   | @smoke |
| AC-001.3  | Given a request, when start date is after end date, then the system rejects the submission with a validation error | Functional   | —      |
| AC-001.4  | Given a request, when the employee already has an overlapping request (any status except Cancelled), then the system prevents duplicate submission | Functional   | —      |
| AC-001.5  | Given a request submission, when the employee adds optional notes/comments, then the notes are stored with the request | Functional   | —      |
| AC-001.6  | Given the visual calendar interface, when the employee selects dates, then the selected range is highlighted and total days shown | Functional   | @smoke |
| AC-001.7  | Given a request submission, the API response time must be < 300ms (P95)                            | Non-Functional | —     |

#### Business Rules

- BR-001: A vacation request must have a start date and end date (both inclusive)
- BR-002: Start date must be >= today + 1 business day
- BR-003: Total days are calculated as business days only (Mon-Fri)
- BR-004: An employee cannot have overlapping requests in Pending or Approved status
- BR-005: Notes/comments are optional, max 500 characters

---

### US-002: Track Request Status

**As an** employee
**I want** to see the current status of all my vacation requests
**So that** I know which are pending, approved, rejected, or cancelled

**Priority**: P1
**Effort**: M
**Dependencies**: US-001

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-002.1  | Given an authenticated employee, when they navigate to "My Requests", then they see a list of all their vacation requests with status | Functional   | @smoke |
| AC-002.2  | Given a request list, when displayed, then each request shows: dates, total days, status, and submission date | Functional   | @smoke |
| AC-002.3  | Given a request with status changes, when the employee views the request detail, then they see a timeline of status transitions | Functional   | —      |
| AC-002.4  | Given the request list, when sorted, then requests are ordered by submission date (newest first) by default | Functional   | —      |
| AC-002.5  | Given the request list, when filtered by status, then only requests matching the selected status are shown | Functional   | —      |
| AC-002.6  | Given request status changes, then the page load time must be < 2 seconds                          | Non-Functional | —     |

#### Business Rules

- BR-006: Request statuses are: Pending, Approved, Rejected, Cancelled
- BR-007: Status transitions follow: Pending → Approved | Rejected | Cancelled
- BR-008: Approved requests can transition to Cancelled (by employee)
- BR-009: Each status transition records: timestamp, actor, and reason (if applicable)

---

### US-003: Cancel Vacation Request

**As an** employee
**I want** to cancel a vacation request I previously submitted
**So that** I can withdraw my request if my plans change

**Priority**: P1
**Effort**: M
**Dependencies**: US-001, US-002

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-003.1  | Given a request with status "Pending", when the employee clicks "Cancel", then the request status changes to "Cancelled" | Functional   | @smoke |
| AC-003.2  | Given a request with status "Approved", when the employee clicks "Cancel", then a confirmation dialog is shown before cancelling | Functional   | @smoke |
| AC-003.3  | Given a cancellation, when confirmed, then the system records the cancellation in the audit trail with timestamp and actor | Functional   | —      |
| AC-003.4  | Given a request with status "Rejected" or "Cancelled", when the employee views it, then no "Cancel" action is available | Functional   | —      |
| AC-003.5  | Given a cancellation of an approved request, when confirmed, then notifications are sent to relevant approvers | Functional   | —      |

#### Business Rules

- BR-010: Only the owning employee can cancel their request
- BR-011: Pending requests can be cancelled without confirmation
- BR-012: Approved requests require explicit confirmation before cancellation
- BR-013: Cancelled requests cannot be un-cancelled (employee must create a new request)
- BR-014: Cancellation of approved requests triggers re-calculation of capacity

---

## Non-Functional Requirements

### Performance

| Metric               | Target     | Measurement              |
| -------------------- | ---------- | ------------------------ |
| API Response P95     | < 300 ms   | Request submission       |
| Page Load            | < 2 s      | My Requests page         |
| Calendar Render      | < 1 s      | Date picker component    |

### Security

- [x] Authentication required (Entra ID / Auth Code + PKCE for SPA)
- [x] Authorization rules defined (employee can only see/manage own requests)
- [x] Data encryption at rest (Azure SQL TDE) and in transit (TLS 1.2+)
- [x] Audit logging required (all CRUD operations)

### Scalability

- Expected concurrent users: 500 (peak season)
- Data growth rate: ~2,000 requests/year (500 employees × ~4 requests each)

### Availability

- Target uptime: 99.5%
- Maintenance window: Weekends 2:00 AM - 6:00 AM

---

## Data Requirements

### New Entities

| Entity          | Description                          | Key Fields                                                                  |
| --------------- | ------------------------------------ | --------------------------------------------------------------------------- |
| Employee        | System user synced from AD           | Id, ExternalId, FullName, Email, DepartmentId, ManagerId, Role, IsActive    |
| Department      | Organizational unit                  | Id, Name, ManagerId                                                         |
| Project         | Work unit within department          | Id, Name, DepartmentId, ManagerId                                           |
| VacationRequest | Core request entity                  | Id, EmployeeId, StartDate, EndDate, TotalDays, Status, Notes, CreatedAt     |
| StatusTransition| Audit of status changes              | Id, RequestId, FromStatus, ToStatus, ChangedBy, ChangedAt, Reason           |

### Modified Entities

_None (greenfield)_

---

## Integration Points

| System  | Direction | Protocol        | Purpose                         |
| ------- | --------- | --------------- | ------------------------------- |
| Entra ID | Inbound  | OAuth 2.0 / JWT | User authentication             |
| Frontend | Outbound | REST API        | SPA consumes backend API        |

---

## Out of Scope

- Approval workflow (F-002)
- Calendar visualization (F-003)
- Active Directory synchronization (F-004)
- ServiceNow integration (F-005)
- Notifications beyond in-app status (F-006)
- Reporting (F-007)
- Vacation balance management (handled in ServiceNow)

## Dependencies

- Entra ID tenant configured with App Registration
- Azure SQL Database provisioned
- Azure Container Apps environment ready
- Frontend project scaffolded (Vue 3 + TypeScript + Vite)

## Open Questions

- Q-001: Should start date allow same-day requests or require minimum 1 business day advance?
- Q-002: Are there blackout periods where no vacations can be requested?
- Q-003: Is there a maximum consecutive vacation days limit?

---

## Next Steps

> Spec generated in `specs/001-vacation-request-management/`. Scenario: **fullstack**.
>
> Recommended next:
>
> 1. Invoke `bolt-mockup` (mode: generate) to produce low-fi wireframes for request submission
>    and tracking flows.
> 2. Iterate with `bolt-mockup` (mode: refine) until stakeholder agreement.
> 3. Then → `bolt-plan` + `bolt-gherkin` (in parallel).
