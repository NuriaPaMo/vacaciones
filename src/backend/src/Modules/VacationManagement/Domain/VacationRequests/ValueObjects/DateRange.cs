using VacationManagement.Domain.Common;

namespace VacationManagement.Domain.VacationRequests.ValueObjects;

// BR-001/003: start ≤ end; TotalBusinessDays = Mon–Fri count (inclusive)
public sealed record DateRange
{
    public DateOnly StartDate { get; }
    public DateOnly EndDate { get; }
    public int TotalBusinessDays { get; }

    private DateRange(DateOnly startDate, DateOnly endDate)
    {
        StartDate = startDate;
        EndDate = endDate;
        TotalBusinessDays = CalculateBusinessDays(startDate, endDate);
    }

    public static DateRange Create(DateOnly startDate, DateOnly endDate)
    {
        if (startDate > endDate)
            throw new DomainException("Start date must be before or equal to end date.");

        return new DateRange(startDate, endDate);
    }

    // Returns true when the two ranges share at least one calendar day
    public bool OverlapsWith(DateRange other) =>
        StartDate <= other.EndDate && EndDate >= other.StartDate;

    private static int CalculateBusinessDays(DateOnly start, DateOnly end)
    {
        var count = 0;
        var current = start;
        while (current <= end)
        {
            if (current.DayOfWeek is not DayOfWeek.Saturday and not DayOfWeek.Sunday)
                count++;
            current = current.AddDays(1);
        }
        return count;
    }
}
