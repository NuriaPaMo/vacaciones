using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;

namespace Notifications.Domain.Application;

// Port interfaces — implemented in Infrastructure layer

public interface INotificationRepository
{
    Task SaveAsync(Notifications.Notification notification, CancellationToken ct);
}

public interface INotificationTemplateRepository
{
    // Returns the single active template for (EventType, Channel); null if not seeded
    Task<Notifications.NotificationTemplate?> GetActiveAsync(
        Notifications.NotificationEventType eventType,
        Notifications.NotificationChannel channel,
        CancellationToken ct);

    Task SaveAsync(Notifications.NotificationTemplate template, CancellationToken ct);
}

public interface ICapacityAlertRepository
{
    // INV-510 dedup check (BR-098): has an alert already been sent for this slot?
    Task<bool> ExistsAsync(
        Guid departmentId, DateOnly periodStart, Notifications.CapacityAlertLevel level,
        CancellationToken ct);

    Task SaveAsync(Notifications.CapacityAlert alert, CancellationToken ct);
}

public interface IEmailSender
{
    // TLS enforced; credentials from Key Vault — never in domain code (T018-QG)
    Task SendAsync(string toEmail, string subject, string htmlBody, CancellationToken ct);
}

public interface ITeamsMessageSender
{
    // BR-095: failure does NOT block email; implementor catches and logs only
    Task SendAsync(string recipientAdId, string message, CancellationToken ct);
}
