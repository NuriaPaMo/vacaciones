using ApprovalWorkflow.Domain.ApprovalWorkflows.ValueObjects;
using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;

namespace ApprovalWorkflow.Domain.ApprovalWorkflows.Events;

public sealed record VacationRequestApprovedAtProjectLevel(
    Guid EventId,
    DateTime OccurredOn,
    VacationRequestId RequestId,
    EmployeeId ApproverId,
    bool IsDelegate,
    EmployeeId? OriginalApproverId) : IDomainEvent;

public sealed record VacationRequestApprovedFinal(
    Guid EventId,
    DateTime OccurredOn,
    VacationRequestId RequestId,
    EmployeeId ApproverId,
    bool IsDelegate) : IDomainEvent;

public sealed record VacationRequestRejectedAtProjectLevel(
    Guid EventId,
    DateTime OccurredOn,
    VacationRequestId RequestId,
    EmployeeId ApproverId,
    string Reason) : IDomainEvent;

public sealed record VacationRequestRejectedFinal(
    Guid EventId,
    DateTime OccurredOn,
    VacationRequestId RequestId,
    EmployeeId ApproverId,
    string Reason) : IDomainEvent;

public sealed record ApprovalEscalationTriggered(
    Guid EventId,
    DateTime OccurredOn,
    VacationRequestId RequestId,
    ApprovalWorkflowId WorkflowId,
    EscalationType EscalationType,
    EmployeeId TargetEmployeeId) : IDomainEvent;
