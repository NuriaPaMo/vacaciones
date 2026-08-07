# Task List — F-006: Notifications

## Metadata

| Property       | Value                                               |
| -------------- | --------------------------------------------------- |
| Feature        | F-006 — Notifications                               |
| Scenario       | Backend-only                                        |
| Source plan    | `planning/plan.md`                                  |
| Gherkin source | `tests/email-notifications.feature` · `tests/capacity-alerts-and-action-links.feature` |
| Steps stub     | `tests/Notifications.ReqnrollTests/StepDefinitions/NotificationSteps.cs` |
| Created        | 2026-08-07                                          |
| Status         | Ready for execution                                 |

---

## Reconciliation plan ↔ Gherkin

### Coverage

| Metric | Count |
|--------|-------|
| Endpoints planned | 3 (send notification, send capacity alert, update template) |
| Endpoints with BDD coverage | 3 |
| `@smoke` scenarios | 9 (3 email + 2 action-link + 2 capacity + 2 Teams) |
| `@smoke` with planned implementation | 9 |
| Gaps | 1 (minor) |

### Gaps detected

- **Minor gap:** US-020 (Action Links in Email) — `capacity-alerts-and-action-links.feature` has `@smoke` for action link validation endpoint (`GET /api/action-links/validate`). The plan mentions `ActionLinkGenerator` but does NOT have an explicit task for the validation **API endpoint**. → **T013 added**: "Implement `GET /api/action-links/validate` endpoint."
- Step definitions stub → **T028** in Bolt 6B.

---

## Auto-Split Log

| Original Bolt | Decision | Reason |
|--------------|----------|--------|
| Bolt 6A (core notification engine) | **Split → Bolt 6A + Bolt 6B** | 12 tasks > 8-task limit |
| Bolt 6B (Teams + capacity alerts + steps) | Kept; 8 tasks, 3.75L | Within limits |

---

## User Story → Bolt Map

| User Story | Priority | Bolt |
|-----------|---------|------|
| US-019 Email Notifications for Workflow Events | P1 | Bolt 6A + 6B |
| US-020 Approver Action Links in Email | P1 | Bolt 6A |
| US-021 Microsoft Teams Notifications | P2 | Bolt 6B |
| US-022 Over-Capacity Alert Notifications | P1 | Bolt 6B |

---

## Bolt 6A — Notification Domain, Templates, Service Bus Consumers & Email Sender

**Goal:** Domain aggregates, template seeding, 6 Service Bus consumers, SMTP email sender, HMAC action links.
**Duration:** 3–4 days · **Weight:** 5.0L equivalent (at limit — kept as single due to cohesion)

### Domain

- [ ] T001 [S] Create `src/Modules/Notifications/` folder structure
- [ ] T002 [M] [US-019] Implement `Notification` aggregate root: `TryMarkSent()`, `TryMarkFailed(error)`, `CanRetry()` (max 3; BR-088), `INV-501–504`
- [ ] T003 [M] [US-019] Implement `NotificationTemplate` aggregate root: `Render(Dictionary<string,object>)` using **Handlebars.NET**; variable substitution (all 11 variables from data model)
- [ ] T004 [M] [US-022] Implement `CapacityAlert` aggregate root (dedup entity): `INV-510–511`; unique composite `(DepartmentId, PeriodStart, Level)` per day

### Infrastructure — Email & Action Links

- [ ] T005 [L] [US-019] Implement `SmtpEmailSender` / `SendGridEmailSender`: TLS connection; Polly retry (3×); `EmailTemplateRenderer` (Handlebars.NET + Avanade branding; HTML output); mark `Notification.Status` on success/failure
- [ ] T006 [M] [US-020] Implement `ActionLinkGenerator`: HMAC-SHA256 signed with Key Vault secret; URL format `/app/requests/{id}?token={hmac}&exp={unix_ts}`; 7-day expiry (BR-089); `Validate(token, recipientId)` — user-scoped check

### Persistence

- [ ] T007 [M] [P] EF Core config for `Notification`, `NotificationTemplate`, `CapacityAlert`; unique constraint `UQ_NT_EventType_Channel_Active`; `UQ_CA_Dept_Period_Level`
- [ ] T008 [M] [P] Migration `M007_CreateNotificationTables` + `M007b_SeedNotificationTemplates` (default HTML templates for all 9 event types × 2 channels)

### Application — Commands & Service Bus Consumers

- [ ] T009 [M] [US-019] `SendNotificationCommand` + handler: resolve active template by `(EventType, Channel)`; render; dispatch to `SmtpEmailSender`; persist `Notification` record (audit); BR-085 (email always sent)
- [ ] T010 [M] [US-019] Wire 6 Service Bus consumer handlers (`VacationRequestSubmittedNotificationHandler`, `VacationApprovedFinalNotificationHandler`, `VacationRejectedNotificationHandler`, `VacationCancelledNotificationHandler`, `EscalationTriggeredNotificationHandler`) — each dispatches `SendNotificationCommand`

### API — Action Link Validation (gap fix)

- [ ] T011 [S] [US-020] `GET /api/action-links/validate?token={}&requestId={}&userId={}` endpoint: validate HMAC + expiry; return `{isValid, redirectPath}` or `{error: "EXPIRED"/"INVALID_TOKEN"}` (BR-089–091)

### Tests

- [ ] T012 [M] [US-019][US-020] xUnit: `Notification.CanRetry()` (true at 0,1,2; false at 3); `ActionLink` expiry (valid before 7 days; expired after); `NotificationTemplate.Render()` all 11 variables replaced
- [ ] T013 [M] [US-019] xUnit + SMTP fake (MailKit): end-to-end `VacationRequestSubmittedNotificationHandler` → template rendered → email sent to PM within 5 min; retry on SMTP failure (2 failures → success on 3rd)

### Quality Gates — Bolt 6A

- [ ] T014-QG `dotnet build --warnaserror` → 0 warnings
- [ ] T015-QG `dotnet test` → 100% pass
- [ ] T016-QG Coverlet line ≥ 80% / branch ≥ 75%
- [ ] T017-QG `dotnet stryker --project Notifications.Application.csproj` → ≥ 70%
- [ ] T018-QG SAST: HMAC secret in Key Vault; SMTP creds in Key Vault — 0 hardcoded secrets

---

## Bolt 6B — Teams Integration, Capacity Alert Dedup, Update Template Command & Steps

**Goal:** Teams sender, capacity alert routing, `UpdateNotificationTemplateCommand`, admin query, Reqnroll steps.
**Duration:** 3 days · **Weight:** 3.75L equivalent

### Application — Capacity Alerts

- [ ] T019 [M] [US-022] `SendCapacityAlertCommand` + handler: dedup via `CapacityAlertRepository.ExistsAsync(dept, date, level)`; route recipients (Warning→DM only; Critical→DM+all affected PMs; BR-099–100); dispatch `SendNotificationCommand` per recipient + Teams message for Critical (BR-100); wire `CapacityThresholdCrossedNotificationHandler` Service Bus consumer
- [ ] T020 [S] [US-019] `UpdateNotificationTemplateCommand` + handler (Admin only): validate template ID exists; update `Subject` + `BodyTemplate`; set `IsActive`; audit via `AuditInterceptor`
- [ ] T021 [S] `GetNotificationTemplatesQuery` + handler (Admin panel — Dapper)

### Infrastructure — Teams

- [ ] T022 [M] [US-021] Implement `TeamsMessageSender`: finds/creates 1:1 chat via Microsoft Graph SDK (`Chat.Create`, `ChatMessage.Send` delegated permissions); plain text format Phase 1 (BR-096); failure does NOT block email (BR-095); logs error only
- [ ] T023 [S] [US-021] Wire Teams sender into `SendCapacityAlertCommand` handler (Critical alerts only — BR-100)

### BDD Step Definitions

- [ ] T024 [M] [P] Implement `NotificationSteps.cs` body methods for `email-notifications.feature` and `capacity-alerts-and-action-links.feature`

### Tests

- [ ] T025 [M] [US-022] xUnit: `CapacityThresholdCrossedNotificationHandler` dedup — second event for same period/level → no email; Critical level → Teams message sent; Warning → DM email only
- [ ] T026 [M] [US-021] xUnit: Teams API failure → email still sent; failure logged but not thrown
- [ ] T027 [M] [US-020] xUnit: action link HMAC validate endpoint — valid token redirects to request page; wrong user → INVALID_TOKEN; expired → EXPIRED + redirect to login with return URL (BR-090)

### Quality Gates — Bolt 6B

- [ ] T028-QG `dotnet build --warnaserror` → 0 warnings
- [ ] T029-QG `dotnet test` → 100% pass
- [ ] T030-QG Coverlet line ≥ 80% / branch ≥ 75%
- [ ] T031-QG Notification latency integration test: event published → email queued < 5 min
- [ ] T032-QG NetArchTest → all rules pass
- [ ] T033-QG SAST → 0 Critical
