using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;

namespace Notifications.Domain.Notifications;

// INV-501: Email always sent (BR-085); INV-502: Teams failure doesn't block email
// INV-503: delivered within 5 min of triggering event
// INV-504: max 3 retry attempts (BR-088)
public sealed class Notification
{
    private const int MaxRetries = 3;

    public Guid Id { get; private set; }
    public NotificationEventType EventType { get; private set; }
    public NotificationChannel Channel { get; private set; }
    public EmployeeId RecipientId { get; private set; }
    public string RecipientEmail { get; private set; }
    public VacationRequestId? RequestId { get; private set; }
    public NotificationStatus Status { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime? SentAt { get; private set; }
    public string? ErrorMessage { get; private set; }
    public int RetryCount { get; private set; }

    private Notification() { RecipientEmail = string.Empty; } // EF Core

    public static Notification Create(
        NotificationEventType eventType,
        NotificationChannel channel,
        EmployeeId recipientId,
        string recipientEmail,
        VacationRequestId? requestId = null) =>
        new()
        {
            Id = Guid.NewGuid(),
            EventType = eventType,
            Channel = channel,
            RecipientId = recipientId,
            RecipientEmail = recipientEmail.ToLowerInvariant(),
            RequestId = requestId,
            Status = NotificationStatus.Pending,
            CreatedAt = DateTime.UtcNow,
            RetryCount = 0
        };

    public bool TryMarkSent()
    {
        if (Status is NotificationStatus.Sent) return false;
        Status = NotificationStatus.Sent;
        SentAt = DateTime.UtcNow;
        ErrorMessage = null;
        return true;
    }

    public bool TryMarkFailed(string errorMessage)
    {
        RetryCount++;
        ErrorMessage = errorMessage;
        Status = RetryCount >= MaxRetries
            ? NotificationStatus.MaxRetriesExceeded
            : NotificationStatus.Failed;
        return Status != NotificationStatus.MaxRetriesExceeded;
    }

    // BR-088: retry up to MaxRetries — returns false once exhausted
    public bool CanRetry() => RetryCount < MaxRetries && Status != NotificationStatus.Sent;
}
