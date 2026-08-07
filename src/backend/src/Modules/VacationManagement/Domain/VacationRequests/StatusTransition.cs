using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;

namespace VacationManagement.Domain.VacationRequests;

// INV-010: append-only; INV-011: Reason required on Rejected; INV-012: optional on Cancelled
public sealed class StatusTransition
{
    public Guid Id { get; private set; }
    public VacationRequestId RequestId { get; private set; }
    public VacationStatus? FromStatus { get; private set; }
    public VacationStatus ToStatus { get; private set; }
    public EmployeeId ChangedByEmployeeId { get; private set; }
    public string ActorName { get; private set; }
    public DateTime ChangedAt { get; private set; }
    public string? Reason { get; private set; }

    private StatusTransition() { ActorName = string.Empty; } // EF Core

    internal static StatusTransition Create(
        VacationRequestId requestId,
        VacationStatus? fromStatus,
        VacationStatus toStatus,
        EmployeeId changedByEmployeeId,
        string actorName,
        string? reason)
    {
        if (toStatus is VacationStatus.Rejected && string.IsNullOrWhiteSpace(reason))
            throw new DomainException("A reason is required when rejecting a request.");

        if (!string.IsNullOrWhiteSpace(reason) && reason.Trim().Length < 10)
            throw new DomainException("Rejection reason must be at least 10 characters.");

        return new StatusTransition
        {
            Id = Guid.NewGuid(),
            RequestId = requestId,
            FromStatus = fromStatus,
            ToStatus = toStatus,
            ChangedByEmployeeId = changedByEmployeeId,
            ActorName = actorName.Trim(),
            ChangedAt = DateTime.UtcNow,
            Reason = string.IsNullOrWhiteSpace(reason) ? null : reason.Trim()
        };
    }
}
