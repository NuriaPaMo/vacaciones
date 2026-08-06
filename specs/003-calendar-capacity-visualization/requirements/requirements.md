# Feature: Calendar & Capacity Visualization

## Metadata

| Property   | Value                                          |
| ---------- | ---------------------------------------------- |
| Feature ID | F-003                                          |
| Issue      | gh#4                                           |
| Author     | Bolt Feature Agent                             |
| Created    | 2026-08-06                                     |
| Status     | Draft                                          |
| Priority   | P1                                             |
| Epic       | Vacation Management & Approval System          |
| Scenario   | fullstack (backend + frontend + cloud-platform) |
| Bolt       | Bolt 3 (Week 9-10)                             |

---

## Business Context

### Problem Statement

Managers have no visibility into team vacation coverage across time periods. They cannot identify
over-requested weeks until it is too late, leading to project coverage gaps. The RFP specifically
requires a "very visual" representation of periods exceeding 70% capacity threshold, particularly
during July (summer peak).

### Business Value

- Proactive identification of over-requested periods before they become critical
- Visual calendar enabling quick team coverage assessment
- Configurable thresholds per department/project (default 70%)
- Executive dashboard for strategic vacation planning
- Drill-down capability from department → project → team → individual

### Target Users

| Persona            | Description                       | Goals                                                |
| ------------------ | --------------------------------- | ---------------------------------------------------- |
| Project Manager    | Views project-level calendar      | Identify coverage gaps for their project             |
| Department Manager | Views department-wide calendar    | Monitor 70% threshold across all projects            |
| Employee           | Views team calendar               | See when teammates are away before requesting        |

---

## User Stories

### US-008: Team Calendar View

**As a** project manager
**I want** to see a visual calendar of my team's vacation schedule
**So that** I can assess project coverage at a glance

**Priority**: P1
**Effort**: L
**Dependencies**: F-001 (VacationRequest), F-002 (Approved status)

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-008.1  | Given an authenticated PM, when they navigate to "Team Calendar", then they see a visual calendar with team members and their vacation periods | Functional   | @smoke |
| AC-008.2  | Given the calendar view, when displayed, then approved vacations are shown in green, pending in yellow, and rejected in red | Functional   | @smoke |
| AC-008.3  | Given the calendar, when the user switches between weekly and monthly views, then the display updates accordingly | Functional   | —      |
| AC-008.4  | Given the calendar, when the user selects a custom date range, then only vacations within that range are displayed | Functional   | —      |
| AC-008.5  | Given the calendar, when filtered by team/project, then only employees from that team/project are shown | Functional   | —      |
| AC-008.6  | Given a calendar with 50 employees, then the rendering time must be < 1 second                     | Non-Functional | —     |

#### Business Rules

- BR-035: Default view is current week (Monday-Friday)
- BR-036: Calendar shows employee names on rows, dates on columns
- BR-037: Color coding: Approved = green, Pending = yellow/orange, Rejected = red
- BR-038: Employees can only see their own team's calendar
- BR-039: PMs see their project members; DMs see entire department

---

### US-009: Capacity Heat Map

**As a** department manager
**I want** to see a heat map showing vacation coverage percentage by period
**So that** I can identify over-requested periods (>70%) before approving new requests

**Priority**: P1
**Effort**: L
**Dependencies**: US-008

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-009.1  | Given the capacity view, when displayed, then each day/week cell shows the percentage of employees on vacation | Functional   | @smoke |
| AC-009.2  | Given a period where coverage is 0-50%, then the cell background is green                          | Functional   | @smoke |
| AC-009.3  | Given a period where coverage is 51-64%, then the cell background is yellow                        | Functional   | —      |
| AC-009.4  | Given a period where coverage is 65-70%, then the cell background is orange with a warning indicator | Functional   | —      |
| AC-009.5  | Given a period where coverage exceeds 70%, then the cell background is red with a critical alert icon | Functional   | @smoke |
| AC-009.6  | Given a critical period (>70%), when the user clicks on the cell, then they see the list of employees contributing to the over-capacity | Functional   | —      |
| AC-009.7  | Given configurable thresholds, when an admin changes the default (70%), then the heat map recalculates using the new threshold | Functional   | —      |

#### Business Rules

- BR-040: Default thresholds: Normal (0-50%), Moderate (51-64%), Warning (65-70%), Critical (>70%)
- BR-041: Thresholds are configurable per department by administrators
- BR-042: Capacity is calculated as: (employees on vacation / total employees) × 100
- BR-043: Only Approved + Pending requests count toward capacity
- BR-044: Capacity considers the organizational level selected (department/project/team)

---

### US-010: Executive Dashboard

**As a** department manager
**I want** a dashboard showing key vacation metrics and alerts
**So that** I can quickly understand the current vacation landscape

**Priority**: P1
**Effort**: M
**Dependencies**: US-008, US-009

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-010.1  | Given an authenticated DM, when they open the dashboard, then they see: current vacation count, available employees, and pending approvals | Functional   | @smoke |
| AC-010.2  | Given the dashboard, when over-requested periods exist in the next 90 days, then they are highlighted with a warning card | Functional   | @smoke |
| AC-010.3  | Given the dashboard, when displayed, then it shows average approval time (last 30 days)            | Functional   | —      |
| AC-010.4  | Given the dashboard, when the user clicks "Export", then a PDF/Excel report is generated with current metrics | Functional   | —      |
| AC-010.5  | Given the dashboard data, then the page load time must be < 2 seconds                              | Non-Functional | —     |

#### Business Rules

- BR-045: Dashboard shows data for the authenticated user's scope (department for DM, project for PM)
- BR-046: "Current vacation count" = employees with Approved vacations including today
- BR-047: "Available employees" = total employees - current vacation count
- BR-048: Over-requested periods alert shows next 90 days from today
- BR-049: Average approval time = mean time from submission to final approval (last 30 days)

---

### US-011: Organizational Level Selection

**As a** manager
**I want** to select the organizational level (department/project/team) for capacity queries
**So that** I can view vacation data at the granularity I need

**Priority**: P2
**Effort**: S
**Dependencies**: US-008, US-009, F-004 (hierarchy data)

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-011.1  | Given the calendar or heat map view, when the user selects "Department" level, then data is aggregated across all projects in the department | Functional   | @smoke |
| AC-011.2  | Given the user selects "Project" level, then data shows only employees from the selected project   | Functional   | —      |
| AC-011.3  | Given the user selects "Team" level, then data shows only employees from the selected team         | Functional   | —      |
| AC-011.4  | Given a level selection, when the user also selects a time period (days/weeks), then counts and percentages are returned for that combination | Functional   | —      |
| AC-011.5  | Given a query result, when displayed, then it shows: total employees at level, employees on vacation, and percentage | Functional   | —      |

#### Business Rules

- BR-050: Organizational levels: Department → Project → Team (single hierarchy)
- BR-051: DMs can query all levels; PMs can query project and team levels only
- BR-052: Time period granularity: by day or by week (configurable)
- BR-053: Query returns count + percentage for the selected level and period

---

## Non-Functional Requirements

### Performance

| Metric              | Target    | Measurement                              |
| ------------------- | --------- | ---------------------------------------- |
| Calendar Render     | < 1 s     | 50 employees × 1 month                  |
| Heat Map Render     | < 1 s     | Department-level (500 employees)         |
| Dashboard Load      | < 2 s     | All widgets with real-time data          |
| Drill-down          | < 500 ms  | Clicking a heat map cell                 |

### Security

- [x] Authentication required (Entra ID)
- [x] Authorization: scope visibility by role (employee/PM/DM)
- [x] No PII exposed in calendar views (only names, not personal details)
- [x] Read-only views (no data modification)

### Scalability

- Expected concurrent viewers: 100 (managers + employees checking calendars)
- Data volume: 500 employees × 365 days/year capacity matrix
- Redis caching for pre-computed capacity percentages

### Availability

- Target uptime: 99.5%
- Cache invalidation: on every approval/rejection/cancellation event

---

## Data Requirements

### New Entities

| Entity             | Description                              | Key Fields                                             |
| ------------------ | ---------------------------------------- | ------------------------------------------------------ |
| CapacitySnapshot   | Pre-computed daily capacity per level    | Id, Date, Level, LevelId, TotalEmployees, OnVacation, Percentage |
| ThresholdConfig    | Per-department capacity thresholds       | Id, DepartmentId, WarningPct, CriticalPct              |

### Modified Entities

| Entity          | Changes                         | Impact                                    |
| --------------- | ------------------------------- | ----------------------------------------- |
| VacationRequest | Index on (Status, StartDate, EndDate) | Performance for calendar queries   |

---

## Integration Points

| System       | Direction | Protocol        | Purpose                              |
| ------------ | --------- | --------------- | ------------------------------------ |
| Redis        | Outbound  | Azure Redis     | Cache capacity snapshots             |
| Service Bus  | Inbound   | Event handler   | Invalidate cache on approval events  |
| Frontend     | Outbound  | REST API        | Calendar, heat map, dashboard APIs   |

---

## Out of Scope

- Approval actions from calendar view (users navigate to F-002 for actions)
- Employee self-service calendar editing
- Integration with external calendar systems (Outlook, Google)
- Predictive analytics for vacation patterns

## Dependencies

- F-001: VacationRequest entity with dates and status
- F-002: Approval workflow (status = Approved) for accurate capacity
- F-004: Organizational hierarchy for level selection (can use seed data initially)

## Open Questions

- Q-007: Should the capacity include Pending requests or only Approved?
- Q-008: Should employees see department-level heat maps or only team-level?
- Q-009: What exact visualization is expected for "very visual" (mockup validation needed)?

---

## Next Steps

> Spec generated in `specs/003-calendar-capacity-visualization/`. Scenario: **fullstack**.
>
> Recommended next:
>
> 1. Invoke `bolt-mockup` (mode: generate) — this feature is HIGHLY visual. Mockup validation
>    with stakeholders is critical before planning.
> 2. Iterate with `bolt-mockup` (mode: refine) until DM stakeholders approve the heat map design.
> 3. Then → `bolt-plan` + `bolt-gherkin` (in parallel).
