using ReportingAdmin.Domain.Configuration;
using System.Text.Json;
using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;

namespace ReportingAdmin.Domain.Configuration;

// INV-610: WarningThreshold ∈ [1,100]; INV-611: CriticalThreshold > WarningThreshold
// INV-612: one config record per (Key, Scope, DepartmentId)
// INV-613: Department scope overrides Global for same key (BR-124)
// INV-614: takes effect immediately — no restart needed (BR-122)
public sealed class SystemConfiguration
{
    public Guid Id { get; private set; }
    public string Key { get; private set; }
    public string Value { get; private set; }
    public ConfigScope Scope { get; private set; }
    public Guid? DepartmentId { get; private set; }
    public DateTime UpdatedAt { get; private set; }
    public EmployeeId UpdatedBy { get; private set; }
    public string? PreviousValue { get; private set; }

    private SystemConfiguration() { Key = string.Empty; Value = string.Empty; }

    public static SystemConfiguration CreateGlobal(string key, string value, EmployeeId createdBy) =>
        new()
        {
            Id = Guid.NewGuid(),
            Key = key,
            Value = value,
            Scope = ConfigScope.Global,
            DepartmentId = null,
            UpdatedAt = DateTime.UtcNow,
            UpdatedBy = createdBy,
            PreviousValue = null
        };

    public static SystemConfiguration CreateForDepartment(
        string key, string value, Guid departmentId, EmployeeId createdBy) =>
        new()
        {
            Id = Guid.NewGuid(),
            Key = key,
            Value = value,
            Scope = ConfigScope.Department,
            DepartmentId = departmentId,
            UpdatedAt = DateTime.UtcNow,
            UpdatedBy = createdBy,
            PreviousValue = null
        };

    // Captures PreviousValue for audit trail (AC-027.5)
    public void Update(string newValue, EmployeeId updatedBy)
    {
        PreviousValue = Value;
        Value = newValue;
        UpdatedAt = DateTime.UtcNow;
        UpdatedBy = updatedBy;
    }

    // Deserialises the stored JSON string into the target type
    public T GetValue<T>() => JsonSerializer.Deserialize<T>(Value)
        ?? throw new DomainException($"Cannot deserialise configuration '{Key}' as {typeof(T).Name}.");

    // INV-613: Department config overrides Global (BR-124)
    public bool IsApplicableTo(Guid? departmentId) =>
        Scope == ConfigScope.Global
        || (Scope == ConfigScope.Department && DepartmentId == departmentId);
}
