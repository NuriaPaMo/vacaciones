using CapacityManagement.Domain.Capacity.ValueObjects;
using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;

namespace CapacityManagement.Domain.Capacity;

// INV-210–213: ThresholdConfig invariants enforced here
// Department scope overrides Global for same key (BR-124)
public sealed class ThresholdConfig
{
    public Guid Id { get; private set; }
    public ThresholdScope Scope { get; private set; }
    public Guid? DepartmentId { get; private set; }
    public int WarningThresholdPct { get; private set; }
    public int CriticalThresholdPct { get; private set; }
    public DateTime UpdatedAt { get; private set; }
    public EmployeeId UpdatedBy { get; private set; }

    private ThresholdConfig() { } // EF Core

    // INV-210: Critical > Warning; INV-211: both in range 1–100
    public static ThresholdConfig CreateGlobal(
        int warningPct, int criticalPct, EmployeeId updatedBy)
    {
        Validate(warningPct, criticalPct);
        return new ThresholdConfig
        {
            Id = Guid.NewGuid(),
            Scope = ThresholdScope.Global,
            DepartmentId = null,
            WarningThresholdPct = warningPct,
            CriticalThresholdPct = criticalPct,
            UpdatedAt = DateTime.UtcNow,
            UpdatedBy = updatedBy
        };
    }

    // INV-212: DepartmentId required for Department scope
    public static ThresholdConfig CreateForDepartment(
        Guid departmentId, int warningPct, int criticalPct, EmployeeId updatedBy)
    {
        Validate(warningPct, criticalPct);
        return new ThresholdConfig
        {
            Id = Guid.NewGuid(),
            Scope = ThresholdScope.Department,
            DepartmentId = departmentId,
            WarningThresholdPct = warningPct,
            CriticalThresholdPct = criticalPct,
            UpdatedAt = DateTime.UtcNow,
            UpdatedBy = updatedBy
        };
    }

    public void Update(int warningPct, int criticalPct, EmployeeId updatedBy)
    {
        Validate(warningPct, criticalPct);
        WarningThresholdPct = warningPct;
        CriticalThresholdPct = criticalPct;
        UpdatedAt = DateTime.UtcNow;
        UpdatedBy = updatedBy;
    }

    // INV-213: Department config overrides Global (BR-124)
    public bool IsApplicableTo(Guid? departmentId) =>
        Scope == ThresholdScope.Global
        || (Scope == ThresholdScope.Department && DepartmentId == departmentId);

    private static void Validate(int warningPct, int criticalPct)
    {
        if (warningPct < 1 || warningPct > 100)
            throw new DomainException($"Warning threshold must be between 1 and 100 (BR-125). Got: {warningPct}");

        if (criticalPct < 1 || criticalPct > 100)
            throw new DomainException($"Critical threshold must be between 1 and 100 (BR-125). Got: {criticalPct}");

        if (criticalPct <= warningPct)
            throw new DomainException($"Critical threshold ({criticalPct}%) must exceed warning threshold ({warningPct}%) (INV-210).");
    }

    // Default seeded configuration (F-007 M009 migration)
    public static ThresholdConfig Default(EmployeeId systemId) =>
        CreateGlobal(warningPct: 65, criticalPct: 70, systemId);
}
