using VacationManagement.Domain.Common;

namespace Notifications.Domain.Notifications;

// INV-510: one alert per (DepartmentId, PeriodStart, Level) per day (BR-098 dedup)
// INV-511: Warning → DM only; Critical → DM + all affected PMs (BR-099–100)
public sealed class CapacityAlert
{
    public Guid Id { get; private set; }
    public Guid DepartmentId { get; private set; }
    public DateOnly PeriodStart { get; private set; }
    public DateOnly PeriodEnd { get; private set; }
    public CapacityAlertLevel Level { get; private set; }
    public decimal CapacityPercent { get; private set; }
    public DateTime AlertedAt { get; private set; }

    private CapacityAlert() { }

    public static CapacityAlert Create(
        Guid departmentId,
        DateOnly periodStart,
        DateOnly periodEnd,
        CapacityAlertLevel level,
        decimal capacityPercent) =>
        new()
        {
            Id = Guid.NewGuid(),
            DepartmentId = departmentId,
            PeriodStart = periodStart,
            PeriodEnd = periodEnd,
            Level = level,
            CapacityPercent = capacityPercent,
            AlertedAt = DateTime.UtcNow
        };
}
