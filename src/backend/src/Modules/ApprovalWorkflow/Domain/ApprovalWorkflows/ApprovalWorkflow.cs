using ApprovalWorkflow.Domain.ApprovalWorkflows.Events;
using ApprovalWorkflow.Domain.ApprovalWorkflows.ValueObjects;
using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;

namespace ApprovalWorkflow.Domain.ApprovalWorkflows;

public sealed class ApprovalWorkflow
{
    private readonly List<ApprovalStep> _steps = [];
    private readonly List<IDomainEvent> _domainEvents = [];

    public ApprovalWorkflowId Id { get; private set; }
    public VacationRequestId RequestId { get; private set; }
    public ApprovalLevel CurrentLevel { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime? CompletedAt { get; private set; }
    public IReadOnlyList<ApprovalStep> Steps => _steps.AsReadOnly();
    public IReadOnlyList<IDomainEvent> DomainEvents => _domainEvents.AsReadOnly();

    private ApprovalWorkflow() { } // EF Core

    // Factory — creates workflow in Project-level state (INV-101)
    public static ApprovalWorkflow Create(VacationRequestId requestId)
    {
        return new ApprovalWorkflow
        {
            Id = ApprovalWorkflowId.New(),
            RequestId = requestId,
            CurrentLevel = ApprovalLevel.Project,
            CreatedAt = DateTime.UtcNow,
            CompletedAt = null
        };
    }

    // INV-104: PM can only act on requests from their projects (enforced by caller / handler)
    public void ApproveAtProjectLevel(
        EmployeeId approverId,
        string approverName,
        EmployeeId? originalApproverId = null,
        string? originalApproverName = null)
    {
        EnsureNotCompleted();
        EnsureCurrentLevel(ApprovalLevel.Project);

        _steps.Add(ApprovalStep.Create(
            Id, ApprovalLevel.Project, ApprovalDecision.Approved,
            approverId, approverName, reason: null,
            originalApproverId, originalApproverName));

        // BR-019a: PM who is also DM — skip straight to completed Approved
        if (originalApproverId.HasValue is false && IsSelfApprovalBothLevels(approverId))
        {
            // Self-approval scenario handled externally by the handler checking roles
        }

        CurrentLevel = ApprovalLevel.Department;

        _domainEvents.Add(new VacationRequestApprovedAtProjectLevel(
            Guid.NewGuid(), DateTime.UtcNow, RequestId, approverId,
            IsDelegate: originalApproverId.HasValue, originalApproverId));
    }

    // INV-103: reason required on rejection (BR-017)
    public void RejectAtProjectLevel(
        EmployeeId approverId,
        string approverName,
        string reason,
        EmployeeId? originalApproverId = null,
        string? originalApproverName = null)
    {
        EnsureNotCompleted();
        EnsureCurrentLevel(ApprovalLevel.Project);

        _steps.Add(ApprovalStep.Create(
            Id, ApprovalLevel.Project, ApprovalDecision.Rejected,
            approverId, approverName, reason,
            originalApproverId, originalApproverName));

        // Rejection at project level is NOT final (BR-016); status = RejectedAtProjectLevel
        _domainEvents.Add(new VacationRequestRejectedAtProjectLevel(
            Guid.NewGuid(), DateTime.UtcNow, RequestId, approverId, reason));
    }

    // INV-105: DM can act on any department request; final approval
    public void ApproveAtDepartmentLevel(
        EmployeeId approverId,
        string approverName,
        EmployeeId? originalApproverId = null,
        string? originalApproverName = null)
    {
        EnsureNotCompleted();
        EnsureDepartmentLevelReachable();

        _steps.Add(ApprovalStep.Create(
            Id, ApprovalLevel.Department, ApprovalDecision.Approved,
            approverId, approverName, reason: null,
            originalApproverId, originalApproverName));

        Complete();
        _domainEvents.Add(new VacationRequestApprovedFinal(
            Guid.NewGuid(), DateTime.UtcNow, RequestId, approverId,
            IsDelegate: originalApproverId.HasValue));
    }

    // INV-105: DM final rejection overrides PM decision (BR-022)
    public void RejectAtDepartmentLevel(
        EmployeeId approverId,
        string approverName,
        string reason,
        EmployeeId? originalApproverId = null,
        string? originalApproverName = null)
    {
        EnsureNotCompleted();
        EnsureDepartmentLevelReachable();

        _steps.Add(ApprovalStep.Create(
            Id, ApprovalLevel.Department, ApprovalDecision.Rejected,
            approverId, approverName, reason,
            originalApproverId, originalApproverName));

        Complete();
        _domainEvents.Add(new VacationRequestRejectedFinal(
            Guid.NewGuid(), DateTime.UtcNow, RequestId, approverId, reason));
    }

    // Used when employee appeals a PM rejection, or DirectEscalation bypasses PM (AC-007.3)
    public void MoveToDepartmentQueue()
    {
        EnsureNotCompleted();
        CurrentLevel = ApprovalLevel.Department;
    }

    // Called by EscalationBackgroundService
    public void RecordEscalation(EscalationType type, EmployeeId targetEmployeeId)
    {
        EnsureNotCompleted();
        _domainEvents.Add(new ApprovalEscalationTriggered(
            Guid.NewGuid(), DateTime.UtcNow, RequestId, Id, type, targetEmployeeId));
    }

    public bool IsCompleted() => CompletedAt.HasValue;

    public void MarkCancelledByEmployee()
    {
        // Workflow terminated because the vacation request was cancelled
        Complete();
    }

    public void ClearDomainEvents() => _domainEvents.Clear();

    private void Complete() => CompletedAt = DateTime.UtcNow;

    private void EnsureNotCompleted()
    {
        if (IsCompleted())
            throw new DomainException("Workflow is already completed (INV-101).");
    }

    private void EnsureCurrentLevel(ApprovalLevel required)
    {
        if (CurrentLevel != required)
            throw new DomainException(
                $"Action requires {required} level but workflow is currently at {CurrentLevel} level.");
    }

    // Department level is reachable from Department state OR when DM overrides a PM rejection
    private void EnsureDepartmentLevelReachable()
    {
        if (CurrentLevel != ApprovalLevel.Department)
            throw new DomainException(
                "Department-level action requires the workflow to be at Department level.");
    }

    // Placeholder — self-approval logic (BR-019a) validated by command handler checking roles
    private static bool IsSelfApprovalBothLevels(EmployeeId _) => false;
}
