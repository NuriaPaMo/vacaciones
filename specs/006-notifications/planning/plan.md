# Technical Plan — F-006: Notifications

## Metadata

| Property          | Value                                               |
| ----------------- | --------------------------------------------------- |
| Feature           | F-006 — Notifications                               |
| Scenario          | Backend-only (admin template UI via F-007)          |
| Bounded Context   | Notifications (Supporting Domain)                   |
| Bolt              | Bolt 6 — Week 15–16                                 |
| Issue             | gh#7                                                |
| Author            | Bolt Plan Agent                                     |
| Created           | 2026-08-07                                          |
| Status            | Draft                                               |
| Dependencies      | F-001 + F-002 workflow events published; F-003 capacity events published |

---

## Executive Summary

F-006 implements **event-driven notifications** via Azure Service Bus consumers. All workflow
events (submitted, approved, rejected, cancelled, escalated) trigger email notifications within
5 minutes. Microsoft Teams notifications (1:1 chat) are activated only for critical capacity
alerts in Phase 1. Notification templates are configurable by administrators. Action links in
emails are user-scoped and time-limited (7-day expiry, HMAC-signed).

---

## Architecture Context

| Concern | Decision |
|---------|----------|
| Module | `src/Modules/Notifications/` |
| Trigger | Azure Service Bus — topic subscriptions per event type |
| Email | SMTP/SendGrid — credentials from Key Vault |
| Teams | Microsoft Graph API (`Chat.Create`, `ChatMessage.Send`) — Managed Identity |
| Templates | `NotificationTemplate` table — configurable by admin; rendered with Handlebars.NET |
| Action links | HMAC-SHA256 signed; user-scoped; 7-day expiry (BR-089) |
| Dedup | `CapacityAlert` table prevents re-alerting same period/level (BR-098) |

---

## Bolt Breakdown

| Bolt | Scope | Focus | Duration |
|------|-------|-------|----------|
| **6A** | Backend | Notification aggregate + templates + Service Bus consumers + email sender | 4 days |
| **6B** | Backend | Teams sender + capacity alert deduplication + action link generation | 3 days |

---

## Bolt 6A — Core Notification Engine

### Module Structure

```
src/Modules/Notifications/
  ├── Domain/
  │   ├── Notification.cs             ← Aggregate Root
  │   ├── NotificationTemplate.cs     ← Aggregate Root
  │   ├── CapacityAlert.cs            ← Aggregate Root (dedup)
  │   └── ValueObjects/
  │       ├── NotificationId.cs
  │       ├── NotificationEventType.cs  ← 9 event types
  │       ├── NotificationChannel.cs    ← Email | Teams
  │       ├── NotificationStatus.cs
  │       ├── CapacityAlertLevel.cs
  │       └── ActionLink.cs            ← HMAC-signed URL
  ├── Application/
  │   ├── Commands/
  │   │   ├── SendNotification/
  │   │   ├── SendCapacityAlert/
  │   │   └── UpdateNotificationTemplate/
  │   ├── Queries/
  │   │   └── GetNotificationTemplates/
  │   └── EventHandlers/
  │       ├── VacationRequestSubmittedNotificationHandler.cs
  │       ├── VacationApprovedFinalNotificationHandler.cs
  │       ├── VacationRejectedNotificationHandler.cs
  │       ├── VacationCancelledNotificationHandler.cs
  │       ├── EscalationTriggeredNotificationHandler.cs
  │       └── CapacityThresholdCrossedNotificationHandler.cs
  ├── Infrastructure/
  │   ├── Email/
  │   │   ├── SmtpEmailSender.cs       ← or SendGridEmailSender.cs
  │   │   └── EmailTemplateRenderer.cs ← Handlebars.NET
  │   ├── Teams/
  │   │   ├── TeamsMessageSender.cs    ← Microsoft.Graph SDK
  │   │   └── TeamsChatResolver.cs    ← finds/creates 1:1 chat (US-021)
  │   ├── ActionLinks/
  │   │   └── ActionLinkGenerator.cs  ← HMAC-SHA256 with Key Vault secret
  │   ├── Persistence/
  │   │   ├── NotificationRepository.cs
  │   │   ├── NotificationTemplateRepository.cs
  │   │   └── CapacityAlertRepository.cs
  │   └── ServiceBus/
  │       └── NotificationServiceBusConsumer.cs
  └── Api/
      └── (admin template endpoints handled by F-007)
```

### Implementation Checklist — Bolt 6A

- [ ] `Notification` aggregate — INV-501–504; `TryMarkSent()`, `TryMarkFailed(error)`, `CanRetry()` (max 3)
- [ ] `NotificationTemplate` aggregate — `Render(Dictionary<string, object>)` using Handlebars.NET
- [ ] Seed default templates for all 9 event types × 2 channels at startup (migration `M007_SeedNotificationTemplates`)
- [ ] `ActionLinkGenerator` — HMAC-SHA256 using Key Vault secret; URL format: `/app/requests/{id}?token={hmac}&exp={unix_ts}`; 7-day expiry (BR-089)
- [ ] `EmailTemplateRenderer` — renders HTML body with `{{variables}}`; applies Avanade branding
- [ ] `SmtpEmailSender` — TLS connection; retry via Polly; marks `Notification.Status`
- [ ] Service Bus consumer handlers (one per event type):
  - `VacationRequestSubmittedNotificationHandler` → sends email to PM with action link (AC-019.1)
  - `VacationApprovedFinalNotificationHandler` → sends email to Employee (AC-019.2)
  - `VacationRejectedNotificationHandler` → sends email to Employee with rejection reason (AC-019.3)
  - `VacationCancelledNotificationHandler` → sends email to PM + DM if approved (AC-019.4)
  - `EscalationTriggeredNotificationHandler` → sends reminder/escalation email (AC-019.5)
  - `CapacityThresholdCrossedNotificationHandler` → routes to `SendCapacityAlertCommand`
- [ ] `SendNotificationCommand` handler — resolves template, renders, dispatches to sender
- [ ] `Notification` persisted for audit (all outcomes: sent, failed, max retries)
- [ ] EF Core migration: `M007_CreateNotificationTables`

---

## Bolt 6B — Teams Integration & Capacity Alerts

### Teams Message Sender

```csharp
public class TeamsMessageSender
{
    // Finds or creates a 1:1 chat between the bot and the recipient (BR-097)
    // Sends a simple text message (adaptive cards deferred to Phase 2, BR-096)
    public async Task SendMessageAsync(string recipientAdId, string message) { ... }
}
```

**Teams message format (Phase 1 — plain text)**

```
🏖️ Vacation System Alert

{employee_name} has submitted a vacation request for {start_date} to {end_date} ({total_days} business days).

View and act on this request: {action_url}
```

### Capacity Alert Deduplication

```csharp
// CapacityThresholdCrossedNotificationHandler
public async Task HandleAsync(CapacityThresholdCrossed @event, CancellationToken ct)
{
    // BR-098: one alert per (department, period, level) per crossing
    var alreadyAlerted = await _capacityAlertRepo
        .ExistsAsync(@event.DepartmentId, @event.AffectedDate, @event.Level, ct);
    if (alreadyAlerted) return;

    await _capacityAlertRepo.SaveAsync(new CapacityAlert(...), ct);

    var recipients = await ResolveRecipients(@event.Level, @event.DepartmentId, ct);
    foreach (var recipient in recipients)
    {
        await _dispatcher.DispatchAsync(new SendNotificationCommand(...), ct);
        // BR-100: Critical → DM + all affected PMs; Warning → DM only
        if (@event.Level == CapacityAlertLevel.Critical)
            await _teamsSender.SendMessageAsync(recipient.AdId, message);
    }
}
```

### Action Link Validation (backend)

```csharp
// Called by the SPA when redirected from email link
// GET /api/action-links/validate?token={token}&requestId={id}&userId={uid}
record ActionLinkValidationResponse(bool IsValid, string? RedirectPath, string? ErrorReason);
// If valid → redirect to /requests/{id}
// If expired → redirect to /login?returnUrl=/requests/{id}  (BR-090)
```

---

## Test Strategy

| Type | Key Scenarios |
|------|---------------|
| Domain Unit | `Notification.CanRetry()` — true at 0,1,2; false at 3 |
| Domain Unit | `ActionLink` — `IsExpired` after 7 days; valid before |
| Domain Unit | `NotificationTemplate.Render()` — all variables replaced correctly |
| Application Unit | `VacationRequestSubmittedNotificationHandler` — email sent to PM with correct template |
| Application Unit | `CapacityThresholdCrossedNotificationHandler` — dedup: second event for same period → no email |
| Application Unit | `CapacityThresholdCrossedNotificationHandler` — Critical level → Teams also sent |
| Integration | End-to-end: Service Bus event → template rendered → email sent (SMTP mock via MailKit SmtpClient fake) |
| Integration | Action link generated → validated → returns correct redirect |
| Integration | Retry: SMTP fails twice → succeeds on 3rd attempt |
| BDD | AC-019.1 `@smoke` — PM receives email on submission |
| BDD | AC-019.2 `@smoke` — Employee receives approval confirmation email |
| BDD | AC-019.3 `@smoke` — Employee receives rejection email with reason |
| BDD | AC-021.1 `@smoke` — Teams message sent for critical capacity alert |
| BDD | AC-022.1 `@smoke` — Warning threshold → DM alert email sent |

---

## Quality Gates

| Gate | Threshold |
|------|-----------|
| Line coverage | ≥ 80% |
| Linting | 0 errors |
| Architecture | All NetArchTest rules pass |
| BDD `@smoke` | 100% |
| Notification latency | < 5 min from event to delivery (integration test measures end-to-end) |
| SAST | 0 Critical (action links HMAC-signed; no sensitive data in email body) |

---

## Risks & Mitigations

| Risk | Prob | Impact | Mitigation |
|------|------|--------|------------|
| SMTP server / SendGrid not configured in time | High | High | Use MailKit SMTP fake for unit/integration tests; get SMTP config in Week 1 |
| Teams API — bot/app registration required | Medium | High | Request Teams app registration in Phase 0; fallback: skip Teams, email-only |
| Action link HMAC secret rotated → all outstanding links invalid | Low | Medium | Use Key Vault versioning; keep previous secret valid for 7 days after rotation |
| Email marked as spam by corporate filter | Medium | Medium | Configure SPF/DKIM; use corporate relay domain; test with real addresses in UAT |
| Capacity alert storms — many events in rapid succession | Medium | Medium | Service Bus deduplication window (5 min) + `CapacityAlert` dedup table |

---

## Dependencies

| Dependency | Type | Status |
|-----------|------|--------|
| F-001 — `VacationRequestSubmitted` published to Service Bus | Hard | Blocks 6A |
| F-002 — Approval events published to Service Bus | Hard | Blocks 6A |
| F-003 — `CapacityThresholdCrossed` published to Service Bus | Hard | Blocks 6B |
| SMTP credentials in Key Vault | Hard | IT admin; request in Phase 0 |
| Teams app registration + Graph API `Chat.*` permissions | Soft | Phase 1 only for capacity alerts; request early |
| Key Vault secret for HMAC signing | Hard | Platform Engineer; Phase 4 |

---

## Open Research Items

| Item | Priority | Owner |
|------|----------|-------|
| Q-017: Employee opt-out from specific notification types? | Resolved | No opt-out in Phase 1 (BR-084) |
| Q-018: Exact Avanade email branding template | High | UX Designer / IT Comms |
| Q-019: Teams to shared channel or 1:1 chat? | Resolved | 1:1 chat (BR-097) |
| Q-020: SMTP relay server details | High | IT Admin |
