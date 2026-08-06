# Feature: Notifications

## Metadata

| Property   | Value                                          |
| ---------- | ---------------------------------------------- |
| Feature ID | F-006                                          |
| Issue      | gh#7                                           |
| Author     | Bolt Feature Agent                             |
| Created    | 2026-08-06                                     |
| Status     | Draft                                          |
| Priority   | P1                                             |
| Epic       | Vacation Management & Approval System          |
| Scenario   | backend-only                                   |
| Bolt       | Bolt 6 (Week 15-16)                            |

---

## Business Context

### Problem Statement

The approval workflow generates events (submitted, approved, rejected, cancelled, escalated) that
must be communicated to relevant parties. Without automated notifications, users must manually
check the system for updates, leading to delays and missed actions. The RFP requires email as
primary channel and Microsoft Teams as secondary (with adaptive cards deferred to Phase 2).

### Business Value

- Instant notification of status changes reduces approval cycle time
- Approvers receive actionable notifications without logging in
- Over-capacity alerts enable proactive decision-making
- Escalation reminders prevent requests from being forgotten
- Teams integration reaches users where they already work

### Target Users

| Persona            | Description                       | Goals                                              |
| ------------------ | --------------------------------- | -------------------------------------------------- |
| Employee           | Receives status notifications     | Know immediately when request is approved/rejected |
| Project Manager    | Receives new request alerts       | Act on approvals quickly without checking the app  |
| Department Manager | Receives escalation alerts        | Never miss a pending request that needs attention  |

---

## User Stories

### US-019: Email Notifications for Workflow Events

**As an** employee
**I want** to receive email notifications when my vacation request status changes
**So that** I am immediately informed without having to check the application

**Priority**: P1
**Effort**: L
**Dependencies**: F-001, F-002 (workflow events trigger notifications)

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-019.1  | Given a new vacation request submitted, then an email is sent to the project manager with request details and a link to approve/reject | Functional   | @smoke |
| AC-019.2  | Given a request approved (final), then an email is sent to the employee confirming approval with dates | Functional   | @smoke |
| AC-019.3  | Given a request rejected, then an email is sent to the employee with rejection reason and a link to the app | Functional   | @smoke |
| AC-019.4  | Given a request cancelled by the employee, then an email is sent to relevant approvers informing them | Functional   | —      |
| AC-019.5  | Given an escalation triggered, then a reminder email is sent to the pending approver               | Functional   | —      |
| AC-019.6  | Given an over-capacity period detected (>70%), then an alert email is sent to the department manager | Functional   | —      |
| AC-019.7  | Given any notification email, then it uses Avanade-branded HTML templates with consistent styling  | Functional   | —      |
| AC-019.8  | Given a notification, then it is delivered within 5 minutes of the triggering event                | Non-Functional | —     |

#### Business Rules

- BR-084: All workflow events trigger email notifications (no opt-out in Phase 1)
- BR-085: Email is the primary notification channel (always sent)
- BR-086: Emails contain embedded action links that deep-link to the relevant page in the app
- BR-087: Email templates are configurable by administrators
- BR-088: Failed email delivery is retried 3 times with exponential backoff

---

### US-020: Approver Action Links in Email

**As a** project manager
**I want** to have action links in notification emails
**So that** I can quickly navigate to the approval page without searching

**Priority**: P1
**Effort**: S
**Dependencies**: US-019

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-020.1  | Given a "new request" notification email, when the PM clicks "View Request", then they are taken directly to the request detail page (authenticated) | Functional   | @smoke |
| AC-020.2  | Given action links, when generated, then they include a secure token that expires after 7 days     | Functional   | —      |
| AC-020.3  | Given an expired action link, when clicked, then the user is redirected to login and then to the relevant page | Functional   | —      |
| AC-020.4  | Given action links, then they are not reusable by other users (token is user-scoped)               | Non-Functional | —     |

#### Business Rules

- BR-089: Action links are user-specific and time-limited (7-day expiry)
- BR-090: Links redirect through authentication if session is expired
- BR-091: Links do NOT auto-approve/reject — they navigate to the page for manual action
- BR-092: Phase 2 will add inline approve/reject via adaptive cards (out of scope now)

---

### US-021: Microsoft Teams Notifications

**As a** project manager
**I want** to receive vacation request notifications in Microsoft Teams
**So that** I am alerted in the tool I use most frequently

**Priority**: P2
**Effort**: M
**Dependencies**: US-019 (same events, different channel)

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-021.1  | Given a workflow event, when Teams notifications are enabled, then a message is sent to the user's Teams chat | Functional   | @smoke |
| AC-021.2  | Given a Teams message, then it includes: event summary, employee name, dates, and a link to the app | Functional   | —      |
| AC-021.3  | Given the Teams message, when the user clicks the link, then they are taken to the relevant page in the vacation app | Functional   | —      |
| AC-021.4  | Given Teams API failures, when they occur, then the system logs the error but does not block the workflow | Functional   | —      |
| AC-021.5  | Given an over-capacity alert, when sent to Teams, then it includes the affected period and current percentage | Functional   | —      |

#### Business Rules

- BR-093: Teams is a secondary channel (email always sent regardless of Teams success)
- BR-094: Teams notifications use Microsoft Graph API (chat messages, not adaptive cards in Phase 1)
- BR-095: Teams delivery failure does not affect the workflow or email delivery
- BR-096: Adaptive cards with inline approve/reject are deferred to Phase 2
- BR-097: Teams messages are sent to 1:1 chat with the user (not channel messages)

---

### US-022: Over-Capacity Alert Notifications

**As a** department manager
**I want** to receive proactive alerts when a period exceeds the capacity threshold
**So that** I can take action before approving additional requests in over-subscribed periods

**Priority**: P1
**Effort**: S
**Dependencies**: F-003 (capacity calculation), US-019

#### Acceptance Criteria

| ID        | Criterion                                                                                          | Type         | Smoke  |
| --------- | -------------------------------------------------------------------------------------------------- | ------------ | ------ |
| AC-022.1  | Given a period that crosses the warning threshold (65-70%), then an alert email is sent to the department manager | Functional   | @smoke |
| AC-022.2  | Given a period that crosses the critical threshold (>70%), then an alert email AND Teams message are sent to DM and relevant PMs | Functional   | —      |
| AC-022.3  | Given the alert, then it includes: period dates, current percentage, employee count, and a link to the capacity view | Functional   | —      |
| AC-022.4  | Given an alert was already sent for a period, when a new request pushes it further over threshold, then no duplicate alert is sent (one per threshold crossing) | Functional   | —      |

#### Business Rules

- BR-098: Alerts are sent once per threshold crossing (no repeated alerts for same period)
- BR-099: Warning alert (65-70%): email to DM only
- BR-100: Critical alert (>70%): email + Teams to DM + all affected PMs
- BR-101: Alert evaluation runs after every approval or cancellation event
- BR-102: Thresholds are the same as configured in F-003

---

## Non-Functional Requirements

### Performance

| Metric               | Target    | Measurement                           |
| -------------------- | --------- | ------------------------------------- |
| Notification Latency | < 5 min   | From event to email delivery          |
| Email Throughput     | 100/min   | Batch notification processing         |
| Teams API Call       | < 3 s     | Single message send                   |

### Security

- [x] No sensitive PII in email bodies (only names, dates, status)
- [x] Action links are user-scoped and time-limited
- [x] SMTP connection uses TLS
- [x] Teams integration uses delegated permissions via Microsoft Graph
- [x] No credentials in notification payloads

### Scalability

- Peak notification volume: 200 notifications/day (summer season)
- Average: 50 notifications/day
- Batch processing for over-capacity alerts (not per-request)

### Availability

- Email delivery: best-effort with retries (not guaranteed real-time)
- Teams delivery: best-effort (failure does not block workflow)
- Notification queue: Azure Service Bus (durable, at-least-once delivery)

---

## Data Requirements

### New Entities

| Entity              | Description                          | Key Fields                                                     |
| ------------------- | ------------------------------------ | -------------------------------------------------------------- |
| Notification        | Record of each notification sent     | Id, Type, Channel (Email/Teams), RecipientId, RequestId, Status, SentAt, ErrorMessage |
| NotificationTemplate| Configurable email/Teams templates   | Id, EventType, Channel, Subject, BodyTemplate, IsActive        |
| CapacityAlert       | Track threshold crossing alerts      | Id, PeriodStart, PeriodEnd, Level, LevelId, Threshold, AlertedAt |

### Modified Entities

_None_

---

## Integration Points

| System            | Direction | Protocol              | Purpose                              |
| ----------------- | --------- | --------------------- | ------------------------------------ |
| SMTP Server       | Outbound  | SMTP/TLS              | Send email notifications             |
| Microsoft Graph   | Outbound  | REST API              | Send Teams chat messages             |
| Azure Service Bus | Inbound   | Message queue         | Receive workflow events for notification processing |
| Azure Key Vault   | Inbound   | Managed Identity      | SMTP credentials, Graph API secrets  |

---

## Out of Scope

- Microsoft Teams adaptive cards with inline approve/reject (Phase 2)
- Teams channel messages (only 1:1 chat in Phase 1)
- SMS notifications
- Push notifications (mobile)
- User notification preferences/opt-out
- Notification digest (daily summary email)

## Dependencies

- SMTP server provided by Avanade IT
- Microsoft 365 tenant with Graph API access
- Azure Service Bus for event-driven notification processing
- F-001 + F-002: Workflow events that trigger notifications
- F-003: Capacity thresholds for over-capacity alerts

## Open Questions

- Q-017: Should employees be able to opt out of certain notification types?
- Q-018: What is the exact Avanade email branding/template to use?
- Q-019: Should Teams messages go to a shared channel or only 1:1 chats?
- Q-020: What SMTP server/relay will be provided?

---

## Next Steps

> Spec generated in `specs/006-notifications/`. Scenario: **backend-only**.
>
> Minimal admin UI for template management. No user-facing frontend for this feature.
>
> Recommended next:
>
> 1. → `bolt-plan` + `bolt-gherkin` (in parallel).
> 2. Clarify Q-017 through Q-020 with Avanade IT via `bolt-clarify`.
