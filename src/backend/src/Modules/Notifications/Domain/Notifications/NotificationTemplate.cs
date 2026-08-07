using System.Text.RegularExpressions;
using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;

namespace Notifications.Domain.Notifications;

// Template rendering uses simple {{variable_name}} substitution (11 standard variables)
// Handlebars.NET is an infrastructure concern — used by EmailTemplateRenderer in the Infra layer
public sealed class NotificationTemplate
{
    // Standard template variables (all 11 from data-model.md)
    public static readonly IReadOnlyList<string> KnownVariables =
    [
        "employee_name", "start_date", "end_date", "total_days",
        "status", "rejection_reason", "action_url", "approver_name",
        "capacity_percent", "period_start", "period_end"
    ];

    public Guid Id { get; private set; }
    public NotificationEventType EventType { get; private set; }
    public NotificationChannel Channel { get; private set; }
    public string Subject { get; private set; }
    public string BodyTemplate { get; private set; }
    public bool IsActive { get; private set; }
    public DateTime UpdatedAt { get; private set; }
    public EmployeeId UpdatedBy { get; private set; }

    private NotificationTemplate() { Subject = string.Empty; BodyTemplate = string.Empty; }

    public static NotificationTemplate Create(
        NotificationEventType eventType,
        NotificationChannel channel,
        string subject,
        string bodyTemplate,
        EmployeeId createdBy) =>
        new()
        {
            Id = Guid.NewGuid(),
            EventType = eventType,
            Channel = channel,
            Subject = subject,
            BodyTemplate = bodyTemplate,
            IsActive = true,
            UpdatedAt = DateTime.UtcNow,
            UpdatedBy = createdBy
        };

    public void Update(string subject, string bodyTemplate, EmployeeId updatedBy)
    {
        Subject = subject;
        BodyTemplate = bodyTemplate;
        UpdatedAt = DateTime.UtcNow;
        UpdatedBy = updatedBy;
    }

    public void Deactivate() => IsActive = false;

    // Replaces {{variable_name}} tokens; any unreplaced tokens are stripped to empty string
    public string Render(IReadOnlyDictionary<string, object> data)
    {
        var result = BodyTemplate;
        foreach (var (key, value) in data)
            result = result.Replace($"{{{{{key}}}}}", value?.ToString() ?? string.Empty,
                StringComparison.OrdinalIgnoreCase);
        // Strip any unreplaced {{...}} tokens
        return Regex.Replace(result, @"\{\{[^}]+\}\}", string.Empty);
    }

    public string RenderSubject(IReadOnlyDictionary<string, object> data)
    {
        var result = Subject;
        foreach (var (key, value) in data)
            result = result.Replace($"{{{{{key}}}}}", value?.ToString() ?? string.Empty,
                StringComparison.OrdinalIgnoreCase);
        return Regex.Replace(result, @"\{\{[^}]+\}\}", string.Empty);
    }
}
