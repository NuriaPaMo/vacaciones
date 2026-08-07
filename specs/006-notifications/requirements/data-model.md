# Domain Model — F-006: Notifications

## Metadata

| Property        | Value                                           |
| --------------- | ----------------------------------------------- |
| Feature         | F-006 — Notifications                           |
| Bounded Context | Notifications (Supporting Domain)               |
| Source          | UC-019 · UC-020 · UC-021 · UC-022 · US-019–022 |
| Created         | 2026-08-07                                      |
| Author          | Bolt DDD Agent                                  |
| Status          | Draft                                           |

---

## Bounded Context Overview

:::mermaid
flowchart TB
    subgraph NB["⚪ Notifications (Supporting Domain)"]
        NT["NotificationTemplate\n(Aggregate Root)"]
        NO["Notification\n(Aggregate Root)"]
        CA["CapacityAlert\n(Aggregate Root)"]
    end

    subgraph SB["🚌 Azure Service Bus"]
        EVT1["VacationRequestSubmitted"]
        EVT2["VacationRequestApprovedFinal"]
        EVT3["VacationRequestRejectedFinal"]
        EVT4["VacationRequestCancelled"]
        EVT5["ApprovalEscalationTriggered"]
        EVT6["CapacityCriticalThresholdCrossed"]
        EVT7["CapacityWarningThresholdCrossed"]
    end

    subgraph CH["📬 Delivery Channels"]
        SMTP["SMTP / SendGrid\n(Email)"]
        GRAPH["Microsoft Graph API\n(Teams 1:1 chat)"]
    end

    SB -->|consumed by| NB
    NT -->|provides template| NO
    NO -->|dispatches to| SMTP
    NO -->|dispatches to| GRAPH
    CA -->|raises| NO

    style NB fill:#f5f5f5,stroke:#616161,stroke-width:2px
    style SB fill:#fff9c4,stroke:#f57f17,stroke-width:1px
    style CH fill:#e8eaf6,stroke:#283593,stroke-width:1px
:::

---

## Aggregate Model

:::mermaid
classDiagram
    class Notification {
        +NotificationId Id
        +NotificationEventType EventType
        +NotificationChannel Channel
        +EmployeeId RecipientId
        +string RecipientEmail
        +VacationRequestId? RequestId
        +NotificationStatus Status
        +DateTime CreatedAt
        +DateTime? SentAt
        +string? ErrorMessage
        +int RetryCount
        +bool TryMarkSent()
        +bool TryMarkFailed(errorMessage)
        +bool CanRetry() bool
    }

    class NotificationTemplate {
        +NotificationTemplateId Id
        +NotificationEventType EventType
        +NotificationChannel Channel
        +string Subject
        +string BodyTemplate
        +bool IsActive
        +DateTime UpdatedAt
        +EmployeeId UpdatedBy
        +string Render(Dictionary~string_object~ data) string
    }

    class CapacityAlert {
        +CapacityAlertId Id
        +Guid DepartmentId
        +DateOnly PeriodStart
        +DateOnly PeriodEnd
        +CapacityAlertLevel Level
        +decimal CapacityPercent
        +DateTime AlertedAt
        +bool HasBeenAlerted(level) bool
    }

    class NotificationEventType {
        <<Enumeration>>
        RequestSubmitted
        RequestApprovedFinal
        RequestRejectedAtProjectLevel
        RequestRejectedFinal
        RequestCancelled
        EscalationReminder
        EscalationDirect
        CapacityWarning
        CapacityCritical
    }

    class NotificationChannel {
        <<Enumeration>>
        Email
        Teams
    }

    class NotificationStatus {
        <<Enumeration>>
        Pending
        Sent
        Failed
        MaxRetriesExceeded
    }

    class CapacityAlertLevel {
        <<Enumeration>>
        Warning
        Critical
    }

    Notification --> NotificationEventType : for event
    Notification --> NotificationChannel : via channel
    Notification --> NotificationStatus : current state
    NotificationTemplate --> NotificationEventType : defines template for
    NotificationTemplate --> NotificationChannel : on channel
    CapacityAlert --> CapacityAlertLevel : level
:::

---

## Entity Definitions

### Notification _(Aggregate Root)_

Represents a single notification delivery attempt to a specific recipient via a specific channel.
Created by event handlers consuming Service Bus messages. Supports up to 3 retry attempts.
Stored for 90 days for audit and troubleshooting.

| Property | Type | Constraints |
|----------|------|-------------|
| `Id` | `NotificationId` | Required, unique, GUID-based |
| `EventType` | `NotificationEventType` | Required; determines template used |
| `Channel` | `NotificationChannel` | `Email` or `Teams` |
| `RecipientId` | `EmployeeId` | Required; the intended recipient |
| `RecipientEmail` | `string` | Denormalized; email address at time of send |
| `RequestId` | `VacationRequestId?` | FK to request; `null` for capacity alerts |
| `Status` | `NotificationStatus` | `Pending → Sent / Failed → MaxRetriesExceeded` |
| `CreatedAt` | `DateTime` (UTC) | When the notification was enqueued |
| `SentAt` | `DateTime?` (UTC) | When delivery was confirmed |
| `ErrorMessage` | `string?` | Last delivery error |
| `RetryCount` | `int` | 0–3; `CanRetry()` returns `false` at 3 |

**Invariants**

| # | Invariant | Source |
|---|-----------|--------|
| INV-501 | Email notifications are always created; Teams is secondary (BR-093, BR-085) | BR-085 |
| INV-502 | Teams failure does not affect email delivery or workflow (BR-095) | BR-095 |
| INV-503 | Notification must be delivered within 5 minutes (SLA, NFR) | AC-019.8 |
| INV-504 | Max 3 retry attempts with exponential backoff | BR-088 |

---

### NotificationTemplate _(Aggregate Root)_

Configurable template for each combination of event type and channel. Administrators can edit
templates via the admin panel (F-007, US-027). Template variables use `{{variable_name}}` syntax.
Active flag allows templates to be deactivated without deletion.

| Property | Type | Constraints |
|----------|------|-------------|
| `Id` | `NotificationTemplateId` | Required, unique, GUID-based |
| `EventType` | `NotificationEventType` | Required |
| `Channel` | `NotificationChannel` | Required |
| `Subject` | `string` | Required for email; max 200 chars; may contain `{{variables}}` |
| `BodyTemplate` | `string` | Required; HTML for email, plain text for Teams; max 10,000 chars |
| `IsActive` | `bool` | Only one active template per `(EventType, Channel)` pair |
| `UpdatedAt` | `DateTime` (UTC) | Audit field |
| `UpdatedBy` | `EmployeeId` | Audit field |

**Template variables (standardised)**

| Variable | Meaning |
|----------|---------|
| `{{employee_name}}` | Full name of the employee who owns the request |
| `{{start_date}}` | Formatted start date of the vacation request |
| `{{end_date}}` | Formatted end date of the vacation request |
| `{{total_days}}` | Number of business days requested |
| `{{status}}` | Current request status |
| `{{rejection_reason}}` | Reason for rejection (when applicable) |
| `{{action_url}}` | Deep-link URL to the request in the app |
| `{{approver_name}}` | Name of the approver who acted |
| `{{capacity_percent}}` | Current capacity percentage (for capacity alerts) |
| `{{period_start}}` | Alert period start (for capacity alerts) |
| `{{period_end}}` | Alert period end (for capacity alerts) |

---

### CapacityAlert _(Aggregate Root)_

Tracks which capacity threshold crossings have already triggered an alert, preventing duplicate
alerts for the same period and level (BR-098). One record per `(Department, PeriodStart, Level)`.

| Property | Type | Constraints |
|----------|------|-------------|
| `Id` | `CapacityAlertId` | Required, unique, GUID-based |
| `DepartmentId` | `Guid` | Required |
| `PeriodStart` | `DateOnly` | The date that crossed the threshold |
| `PeriodEnd` | `DateOnly` | For multi-day alerts; typically same as `PeriodStart` |
| `Level` | `CapacityAlertLevel` | `Warning` or `Critical` |
| `CapacityPercent` | `decimal` | Percentage at time of alert |
| `AlertedAt` | `DateTime` (UTC) | When the alert was sent |

**Invariants**

| # | Invariant | Source |
|---|-----------|--------|
| INV-510 | Only one alert per `(DepartmentId, PeriodStart, Level)` per day | BR-098 |
| INV-511 | Warning → DM only; Critical → DM + all affected PMs (BR-099, BR-100) | BR-099, BR-100 |

---

## Event → Recipient → Channel Matrix

| Event | Recipient(s) | Email | Teams | Source |
|-------|-------------|-------|-------|--------|
| `RequestSubmitted` | Project Manager | ✔ | Phase 2 | AC-019.1 |
| `RequestApprovedFinal` | Employee | ✔ | — | AC-019.2 |
| `RequestRejectedAtProjectLevel` | Employee | ✔ | — | AC-019.3 |
| `RequestRejectedFinal` | Employee | ✔ | — | AC-019.3 |
| `RequestCancelled` | PM + DM (if approved) | ✔ | — | AC-019.4 |
| `EscalationReminder` | Project Manager | ✔ | — | AC-019.5 |
| `EscalationDirect` | Department Manager | ✔ | Phase 1 | AC-007.2 |
| `CapacityWarning` (65–70%) | Department Manager | ✔ | — | BR-099 |
| `CapacityCritical` (>70%) | DM + affected PMs | ✔ | ✔ | BR-100 |

> **Teams Phase 1:** Only critical capacity alerts trigger Teams. Full Teams workflow notifications
> are deferred to Phase 2 (BR-094).

---

## Action Link Generation

Action links embedded in emails must be user-scoped and time-limited (BR-089).

```csharp
// Value object representing a secure action link
public record ActionLink
{
    public string Url { get; }
    public EmployeeId RecipientId { get; }
    public DateTime ExpiresAt { get; }      // CreatedAt + 7 days (BR-089)
    public bool IsExpired => DateTime.UtcNow > ExpiresAt;

    // Signed with HMAC using Key Vault secret — no auto-approval, navigation only (BR-091)
    public static ActionLink Generate(VacationRequestId requestId, EmployeeId recipientId) { ... }
    public static bool Validate(string token, EmployeeId recipientId) { ... }
}
```

---

## Notification Processing Flow

:::mermaid
sequenceDiagram
    participant SB as Service Bus
    participant NH as NotificationHandler
    participant TR as TemplateRepository
    participant NS as NotificationSender
    participant SMTP as SMTP/SendGrid
    participant TEAMS as Microsoft Graph

    SB->>NH: VacationRequestApprovedFinal event
    NH->>NH: Determine recipients (Employee)
    NH->>TR: GetTemplate(Approved, Email)
    TR-->>NH: NotificationTemplate
    NH->>NH: Render(template, event data)
    NH->>NH: GenerateActionLink(requestId, employeeId)
    NH->>NS: Send(notification)
    NS->>SMTP: POST /send (TLS)
    alt Success
        SMTP-->>NS: 202 Accepted
        NS->>NH: MarkSent()
    else Failure (retry ≤ 3)
        SMTP-->>NS: Error
        NS->>NS: Retry with backoff 1s→5s→30s
    else MaxRetries
        NS->>NH: MarkMaxRetriesExceeded()
    end
    NH->>NH: Persist Notification record (audit)
:::

---

## Domain Events

```csharp
// Raised when a notification is successfully delivered
public record NotificationSent(
    Guid EventId, DateTime OccurredOn,
    NotificationId NotificationId,
    NotificationChannel Channel,
    EmployeeId RecipientId
) : IDomainEvent;

// Raised when all retries exhausted — consumed by F-007 audit log
public record NotificationPermanentlyFailed(
    Guid EventId, DateTime OccurredOn,
    NotificationId NotificationId,
    NotificationChannel Channel,
    EmployeeId RecipientId,
    string LastError
) : IDomainEvent;
```

---

## Database Schema (Azure SQL)

:::mermaid
erDiagram
    NOTIFICATIONS {
        uniqueidentifier Id PK
        tinyint EventType
        tinyint Channel
        uniqueidentifier RecipientId FK
        nvarchar_256 RecipientEmail
        uniqueidentifier RequestId FK
        tinyint Status
        datetime2 CreatedAt
        datetime2 SentAt
        nvarchar_2000 ErrorMessage
        int RetryCount
    }

    NOTIFICATION_TEMPLATES {
        uniqueidentifier Id PK
        tinyint EventType
        tinyint Channel
        nvarchar_200 Subject
        nvarchar_max BodyTemplate
        bit IsActive
        datetime2 UpdatedAt
        uniqueidentifier UpdatedBy FK
    }

    CAPACITY_ALERTS {
        uniqueidentifier Id PK
        uniqueidentifier DepartmentId FK
        date PeriodStart
        date PeriodEnd
        tinyint Level
        decimal_5_2 CapacityPercent
        datetime2 AlertedAt
    }
:::

**Index strategy**

| Table | Index | Columns | Purpose |
|-------|-------|---------|---------|
| `NOTIFICATIONS` | `IX_NO_RecipientId_CreatedAt` | `RecipientId`, `CreatedAt` | Recipient notification history |
| `NOTIFICATIONS` | `IX_NO_Status_RetryCount` | `Status`, `RetryCount` | Pending retry queue |
| `NOTIFICATION_TEMPLATES` | `UQ_NT_EventType_Channel_Active` | `EventType`, `Channel`, `IsActive` | One active template per type/channel |
| `CAPACITY_ALERTS` | `UQ_CA_Dept_Period_Level` | `DepartmentId`, `PeriodStart`, `Level` | Prevent duplicate alerts (BR-098) |

---

## CQRS Commands and Queries

### Commands (F-006)

```csharp
// Triggered by Service Bus event handlers
public record SendNotificationCommand(
    NotificationEventType EventType,
    EmployeeId RecipientId,
    VacationRequestId? RequestId,
    Dictionary<string, object> TemplateData
) : ICommand<NotificationId>;

// Triggered by capacity threshold event handlers
public record SendCapacityAlertCommand(
    Guid DepartmentId,
    DateOnly PeriodStart,
    DateOnly PeriodEnd,
    CapacityAlertLevel Level,
    decimal CapacityPercent,
    List<EmployeeId> Recipients
) : ICommand;

// Admin: update email/Teams template (US-027, AC-027.4)
public record UpdateNotificationTemplateCommand(
    NotificationTemplateId TemplateId,
    string Subject,
    string BodyTemplate,
    EmployeeId UpdatedBy
) : ICommand;
```

### Queries (F-006)

```csharp
// Admin: view notification templates
public record GetNotificationTemplatesQuery(
    NotificationEventType? EventType = null
) : IQuery<IReadOnlyList<NotificationTemplateDto>>;
```

---

## Ubiquitous Language

| Term | Definition | Context |
|------|------------|---------|
| **Notification** | A single delivery of a message to a recipient via a specific channel | Notifications |
| **Event Type** | The business event that triggered the notification (e.g., `RequestApprovedFinal`) | Notifications |
| **Channel** | The delivery medium: Email (primary) or Teams (secondary) | Notifications |
| **Notification Template** | Configurable HTML/text layout with `{{variable}}` placeholders | Notifications |
| **Action Link** | A user-scoped, time-limited URL embedded in notification emails (BR-089) | Notifications |
| **Capacity Alert** | A proactive notification sent when a department period exceeds a threshold | Notifications |
| **Deduplication** | Ensuring only one alert per `(department, period, level)` per crossing event | Notifications |
| **Retry** | Re-sending a failed notification up to 3 times with exponential backoff | Notifications |

---

## Integration with Other Bounded Contexts

| Bounded Context | Direction | Mechanism | Data |
|-----------------|-----------|-----------|------|
| **VacationManagement (F-001)** | Inbound (events) | Service Bus | `VacationRequestSubmitted`, `VacationRequestCancelled` |
| **ApprovalWorkflow (F-002)** | Inbound (events) | Service Bus | Approved, rejected, escalation events |
| **CapacityManagement (F-003)** | Inbound (events) | Service Bus | `CapacityWarningThresholdCrossed`, `CapacityCriticalThresholdCrossed` |
| **SMTP Server** | Outbound | SMTP/TLS | Email delivery |
| **Microsoft Graph API** | Outbound | HTTP REST | Teams 1:1 chat messages |
| **Azure Key Vault** | Inbound | Managed Identity | SMTP credentials, Graph API token |
