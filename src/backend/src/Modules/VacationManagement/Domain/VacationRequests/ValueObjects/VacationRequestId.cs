namespace VacationManagement.Domain.VacationRequests.ValueObjects;

public readonly record struct VacationRequestId(Guid Value)
{
    public static VacationRequestId New() => new(Guid.NewGuid());
    public static VacationRequestId From(Guid value) => new(value);
    public override string ToString() => Value.ToString();
}
