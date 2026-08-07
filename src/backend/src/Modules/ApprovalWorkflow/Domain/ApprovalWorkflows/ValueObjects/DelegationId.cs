namespace ApprovalWorkflow.Domain.ApprovalWorkflows.ValueObjects;

public readonly record struct DelegationId(Guid Value)
{
    public static DelegationId New() => new(Guid.NewGuid());
    public static DelegationId From(Guid value) => new(value);
    public override string ToString() => Value.ToString();
}
