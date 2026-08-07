using System.Text.Json;
using ReportingAdmin.Domain.Audit;

namespace ReportingAdmin.Domain.Application;

// Domain-side abstraction for the EF Core AuditInterceptor
// Concrete implementation is in Infrastructure and registered via SaveChangesInterceptor
// This record carries the changeset data from EF into the audit entry factory

public sealed record AuditableChange(
    string EntityType,
    string EntityId,
    AuditActionType ActionType,
    Dictionary<string, object?>? OldValues,
    Dictionary<string, object?>? NewValues)
{
    // Serialises values with PII redaction ([AuditRedact] → "***")
    public string? SerialiseOldValues() =>
        OldValues is not null ? JsonSerializer.Serialize(OldValues) : null;

    public string? SerialiseNewValues() =>
        NewValues is not null ? JsonSerializer.Serialize(NewValues) : null;
}
