namespace Notifications.Domain.Notifications;

// BR-085: Email is always sent (primary channel); Teams is secondary
public enum NotificationChannel
{
    Email,
    Teams
}
