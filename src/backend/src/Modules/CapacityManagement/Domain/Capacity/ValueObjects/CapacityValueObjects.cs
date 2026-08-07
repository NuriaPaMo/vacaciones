using CapacityManagement.Domain.Capacity.ValueObjects;
using VacationManagement.Domain.Common;

namespace CapacityManagement.Domain.Capacity.ValueObjects;

// BR-040 boundary logic — must be kept in sync with UI heat-map colour thresholds
public static class CapacityColorExtensions
{
    public static CapacityColor FromPercentage(decimal percentage, ThresholdConfig config)
    {
        if (percentage > config.CriticalThresholdPct) return CapacityColor.Red;
        if (percentage >= config.WarningThresholdPct) return CapacityColor.Orange;
        if (percentage > 50m) return CapacityColor.Yellow;
        return CapacityColor.Green;
    }
}

// VO: a date range with granularity — used by heat-map and calendar queries
public sealed record CapacityPeriod
{
    public DateOnly StartDate { get; }
    public DateOnly EndDate { get; }
    public CapacityGranularity Granularity { get; }

    private CapacityPeriod(DateOnly start, DateOnly end, CapacityGranularity granularity)
    {
        StartDate = start;
        EndDate = end;
        Granularity = granularity;
    }

    public static CapacityPeriod Create(DateOnly start, DateOnly end,
        CapacityGranularity granularity = CapacityGranularity.Daily)
    {
        if (start > end)
            throw new DomainException("CapacityPeriod start must be before or equal to end.");
        return new(start, end, granularity);
    }

    // Returns each day (Daily) or Monday of each week (Weekly) within the period
    public IEnumerable<DateOnly> GetDates()
    {
        if (Granularity == CapacityGranularity.Daily)
        {
            var d = StartDate;
            while (d <= EndDate)
            {
                yield return d;
                d = d.AddDays(1);
            }
        }
        else
        {
            // Align to the Monday of the start week
            var d = StartDate;
            while (d.DayOfWeek != DayOfWeek.Monday)
                d = d.AddDays(-1);

            while (d <= EndDate)
            {
                yield return d;
                d = d.AddDays(7);
            }
        }
    }

    public static CapacityPeriod Next90Days(DateOnly from) =>
        Create(from, from.AddDays(90));
}

// VO: suggested low-capacity alternative when a period is over-requested (BR-044b)
public sealed record AlternativeDateSuggestion(
    DateOnly SuggestedStart,
    DateOnly SuggestedEnd,
    decimal ProjectedCapacityPercent,
    CapacityColor ProjectedColor);
