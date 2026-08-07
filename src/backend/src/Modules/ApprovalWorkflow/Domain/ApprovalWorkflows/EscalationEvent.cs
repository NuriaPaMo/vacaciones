using ApprovalWorkflow.Domain.ApprovalWorkflows.ValueObjects;
using VacationManagement.Domain.VacationRequests.ValueObjects;

namespace ApprovalWorkflow.Domain.ApprovalWorkflows;

// EscalationThreshold: configurable per department via SystemConfiguration (F-007)
public sealed record EscalationThreshold(int ReminderAfterDays, int EscalationAfterDays)
{
    public static EscalationThreshold Default => new(ReminderAfterDays: 3, EscalationAfterDays: 5);

    // BR-034: only business days count
    public bool ShouldSendReminder(int pendingBusinessDays) =>
        pendingBusinessDays >= ReminderAfterDays;

    public bool ShouldEscalate(int pendingBusinessDays) =>
        pendingBusinessDays >= EscalationAfterDays;
}

public sealed class EscalationEvent
{
    public Guid Id { get; private set; }
    public ApprovalWorkflowId WorkflowId { get; private set; }
    public VacationRequestId RequestId { get; private set; }
    public EscalationType Type { get; private set; }
    public ApprovalLevel Level { get; private set; }
    public EmployeeId TargetEmployeeId { get; private set; }
    public DateTime TriggeredAt { get; private set; }
    public DateTime? ResolvedAt { get; private set; }
    public bool IsResolved { get; private set; }

    private EscalationEvent() { } // EF Core

    public static EscalationEvent Create(
        ApprovalWorkflowId workflowId,
        VacationRequestId requestId,
        EscalationType type,
        ApprovalLevel level,
        EmployeeId targetEmployeeId) =>
        new()
        {
            Id = Guid.NewGuid(),
            WorkflowId = workflowId,
            RequestId = requestId,
            Type = type,
            Level = level,
            TargetEmployeeId = targetEmployeeId,
            TriggeredAt = DateTime.UtcNow,
            ResolvedAt = null,
            IsResolved = false
        };

    public void Resolve()
    {
        IsResolved = true;
        ResolvedAt = DateTime.UtcNow;
    }
}
