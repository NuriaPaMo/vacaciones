namespace ApprovalWorkflow.Domain.ApprovalWorkflows.ValueObjects;

public readonly record struct ApprovalWorkflowId(Guid Value)
{
    public static ApprovalWorkflowId New() => new(Guid.NewGuid());
    public static ApprovalWorkflowId From(Guid value) => new(value);
    public override string ToString() => Value.ToString();
}
