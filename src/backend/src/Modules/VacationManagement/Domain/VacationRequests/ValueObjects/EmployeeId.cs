namespace VacationManagement.Domain.VacationRequests.ValueObjects;

public readonly record struct EmployeeId(Guid Value)
{
    public static EmployeeId New() => new(Guid.NewGuid());
    public static EmployeeId From(Guid value) => new(value);
    public override string ToString() => Value.ToString();
}
