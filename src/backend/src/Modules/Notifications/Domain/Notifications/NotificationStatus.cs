namespace Notifications.Domain.Notifications;

public enum NotificationStatus
{
    Pending,
    Sent,
    Failed,
    MaxRetriesExceeded
}
