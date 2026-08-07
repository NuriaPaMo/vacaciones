using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;

namespace ReportingAdmin.Domain.Audit;

// INV-601: append-only — no Update or Delete (HasNoUpdate() + HasNoDelete() in EF config)
// INV-602: Timestamp is always UTC, set by AuditInterceptor (not the application clock)
// INV-603: PII fields redacted via [AuditRedact] attribute
// INV-604: minimum retention 7 years
public sealed class AuditEntry
{
    public Guid Id { get; private set; }
    public DateTime Timestamp { get; private set; }
    public EmployeeId? UserId { get; private set; }
    public string UserDisplayName { get; private set; }
    public AuditActionType ActionType { get; private set; }
    public string EntityType { get; private set; }
    public string EntityId { get; private set; }
    public string? OldValuesJson { get; private set; }
    public string? NewValuesJson { get; private set; }
    public string? AdditionalContext { get; private set; }
    public AuditSource Source { get; private set; }

    private AuditEntry()
    {
        UserDisplayName = string.Empty;
        EntityType = string.Empty;
        EntityId = string.Empty;
    }

    // Factory — called by AuditInterceptor in same SaveChanges transaction
    public static AuditEntry Create(
        EmployeeId? userId,
        string userDisplayName,
        AuditActionType actionType,
        string entityType,
        string entityId,
        string? oldValuesJson,
        string? newValuesJson,
        AuditSource source,
        string? additionalContext = null) =>
        new()
        {
            Id = Guid.NewGuid(),
            Timestamp = DateTime.UtcNow,    // INV-602: always UTC
            UserId = userId,
            UserDisplayName = userDisplayName,
            ActionType = actionType,
            EntityType = entityType,
            EntityId = entityId,
            OldValuesJson = oldValuesJson,
            NewValuesJson = newValuesJson,
            Source = source,
            AdditionalContext = additionalContext
        };
}
