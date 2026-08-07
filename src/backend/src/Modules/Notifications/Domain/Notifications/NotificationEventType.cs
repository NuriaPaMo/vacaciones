namespace Notifications.Domain.Notifications;

// 9 event types that trigger notifications (BR-084: all workflow events → email)
public enum NotificationEventType
{
    RequestSubmitted,
    RequestApprovedFinal,
    RequestRejectedAtProjectLevel,
    RequestRejectedFinal,
    RequestCancelled,
    EscalationReminder,
    EscalationDirect,
    CapacityWarning,
    CapacityCritical
}
