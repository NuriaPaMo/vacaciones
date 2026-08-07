using CapacityManagement.Domain.Capacity.ValueObjects;
using VacationManagement.Domain.Common;

namespace CapacityManagement.Domain.Capacity;

// INV-201–204: CapacitySnapshot aggregate root
// Pre-computed per (Date, Level, LevelEntityId) — upserted by RecomputeCapacitySnapshotsCommand
public sealed class CapacitySnapshot
{
    public Guid Id { get; private set; }
    public DateOnly Date { get; private set; }
    public OrganizationLevel Level { get; private set; }
    public Guid LevelEntityId { get; private set; }
    public int TotalEmployees { get; private set; }
    public int EmployeesOnVacation { get; private set; }
    public int EmployeesPending { get; private set; }
    public decimal CapacityPercentage { get; private set; }
    public bool IsCritical { get; private set; }
    public bool IsWarning { get; private set; }
    public DateTime ComputedAt { get; private set; }

    private CapacitySnapshot() { } // EF Core

    // INV-204: TotalEmployees == 0 guard applied at handler level; snapshot still created with 0%
    public static CapacitySnapshot Compute(
        DateOnly date,
        OrganizationLevel level,
        Guid levelEntityId,
        int totalEmployees,
        int employeesOnVacation,
        int employeesPending,
        ThresholdConfig threshold)
    {
        if (totalEmployees < 0) throw new DomainException("TotalEmployees cannot be negative.");
        if (employeesOnVacation < 0) throw new DomainException("EmployeesOnVacation cannot be negative.");
        if (employeesPending < 0) throw new DomainException("EmployeesPending cannot be negative.");

        var pct = totalEmployees == 0
            ? 0m
            : Math.Round((decimal)(employeesOnVacation + employeesPending) / totalEmployees * 100, 2);

        return new CapacitySnapshot
        {
            Id = Guid.NewGuid(),
            Date = date,
            Level = level,
            LevelEntityId = levelEntityId,
            TotalEmployees = totalEmployees,
            EmployeesOnVacation = employeesOnVacation,
            EmployeesPending = employeesPending,
            CapacityPercentage = pct,
            IsCritical = pct > threshold.CriticalThresholdPct,
            IsWarning = pct >= threshold.WarningThresholdPct && pct <= threshold.CriticalThresholdPct,
            ComputedAt = DateTime.UtcNow
        };
    }

    // INV-201: uniqueness key is (Date, Level, LevelEntityId) — enforced at DB via UQ_CS_Date_Level_Entity
    public bool IsSameSlot(DateOnly date, OrganizationLevel level, Guid entityId) =>
        Date == date && Level == level && LevelEntityId == entityId;

    public CapacityColor GetColor(ThresholdConfig threshold) =>
        CapacityColorExtensions.FromPercentage(CapacityPercentage, threshold);

    // Re-applies computation in-place (for upsert scenarios)
    public void Recompute(int totalEmployees, int onVacation, int pending, ThresholdConfig threshold)
    {
        TotalEmployees = totalEmployees;
        EmployeesOnVacation = onVacation;
        EmployeesPending = pending;

        CapacityPercentage = totalEmployees == 0
            ? 0m
            : Math.Round((decimal)(onVacation + pending) / totalEmployees * 100, 2);

        IsCritical = CapacityPercentage > threshold.CriticalThresholdPct;
        IsWarning = CapacityPercentage >= threshold.WarningThresholdPct && CapacityPercentage <= threshold.CriticalThresholdPct;
        ComputedAt = DateTime.UtcNow;
    }
}
