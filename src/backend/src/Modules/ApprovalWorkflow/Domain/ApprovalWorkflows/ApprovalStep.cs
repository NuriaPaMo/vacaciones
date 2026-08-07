using ApprovalWorkflow.Domain.ApprovalWorkflows.ValueObjects;
using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;

namespace ApprovalWorkflow.Domain.ApprovalWorkflows;

// INV-010: append-only; INV-011: Reason mandatory on Rejected (≥ 10 chars)
public sealed class ApprovalStep
{
    public Guid Id { get; private set; }
    public ApprovalWorkflowId WorkflowId { get; private set; }
    public ApprovalLevel Level { get; private set; }
    public ApprovalDecision Decision { get; private set; }
    public EmployeeId ApproverId { get; private set; }
    public string ApproverName { get; private set; }
    public DateTime ActedAt { get; private set; }
    public string? Reason { get; private set; }
    public bool IsDelegate { get; private set; }
    public EmployeeId? OriginalApproverId { get; private set; }
    public string? OriginalApproverName { get; private set; }

    private ApprovalStep() { ApproverName = string.Empty; } // EF Core

    internal static ApprovalStep Create(
        ApprovalWorkflowId workflowId,
        ApprovalLevel level,
        ApprovalDecision decision,
        EmployeeId approverId,
        string approverName,
        string? reason,
        EmployeeId? originalApproverId = null,
        string? originalApproverName = null)
    {
        if (decision == ApprovalDecision.Rejected)
        {
            if (string.IsNullOrWhiteSpace(reason))
                throw new DomainException("A reason is required when rejecting a request.");

            if (reason.Trim().Length < 10)
                throw new DomainException("Rejection reason must be at least 10 characters (BR-017).");
        }

        return new ApprovalStep
        {
            Id = Guid.NewGuid(),
            WorkflowId = workflowId,
            Level = level,
            Decision = decision,
            ApproverId = approverId,
            ApproverName = approverName.Trim(),
            ActedAt = DateTime.UtcNow,
            Reason = string.IsNullOrWhiteSpace(reason) ? null : reason.Trim(),
            IsDelegate = originalApproverId.HasValue,
            OriginalApproverId = originalApproverId,
            OriginalApproverName = originalApproverName?.Trim()
        };
    }
}
