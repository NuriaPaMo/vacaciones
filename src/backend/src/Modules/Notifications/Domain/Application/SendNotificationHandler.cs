using Notifications.Domain.Notifications;
using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;

namespace Notifications.Domain.Application;

// Command: dispatch one notification to one recipient on one channel
public sealed record SendNotificationCommand(
    NotificationEventType EventType,
    NotificationChannel Channel,
    EmployeeId RecipientId,
    string RecipientEmail,
    VacationRequestId? RequestId,
    IReadOnlyDictionary<string, object> TemplateData);

// Handler — resolves template, renders, dispatches to email/teams sender, persists audit record
public sealed class SendNotificationHandler
{
    private readonly INotificationTemplateRepository _templates;
    private readonly INotificationRepository _notifications;
    private readonly IEmailSender _email;

    public SendNotificationHandler(
        INotificationTemplateRepository templates,
        INotificationRepository notifications,
        IEmailSender email)
    {
        _templates = templates;
        _notifications = notifications;
        _email = email;
    }

    public async Task HandleAsync(SendNotificationCommand cmd, CancellationToken ct = default)
    {
        var notification = Notification.Create(
            cmd.EventType, cmd.Channel, cmd.RecipientId,
            cmd.RecipientEmail, cmd.RequestId);

        var template = await _templates.GetActiveAsync(cmd.EventType, cmd.Channel, ct);

        if (template is null)
        {
            // No template seeded yet — mark as failed and return; do not throw
            notification.TryMarkFailed($"No active template for {cmd.EventType}/{cmd.Channel}");
            await _notifications.SaveAsync(notification, ct);
            return;
        }

        var subject = template.RenderSubject(cmd.TemplateData);
        var body = template.Render(cmd.TemplateData);

        try
        {
            if (cmd.Channel == NotificationChannel.Email)
                await _email.SendAsync(cmd.RecipientEmail, subject, body, ct);

            notification.TryMarkSent();
        }
        catch (Exception ex)
        {
            notification.TryMarkFailed(ex.Message);
        }

        await _notifications.SaveAsync(notification, ct);
    }
}
