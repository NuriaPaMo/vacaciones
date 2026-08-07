using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.Events;
using VacationManagement.Domain.VacationRequests.ValueObjects;

namespace VacationManagement.Domain.VacationRequests;

public sealed class VacationRequest
{
    // Allowed state machine transitions — keyed by current status → set of valid next statuses
    private static readonly Dictionary<VacationStatus, HashSet<VacationStatus>> _allowedTransitions = new()
    {
        [VacationStatus.Pending] = [
            VacationStatus.PendingDepartmentApproval,
            VacationStatus.RejectedAtProjectLevel,
            VacationStatus.Cancelled
        ],
        [VacationStatus.PendingDepartmentApproval] = [
            VacationStatus.Approved,
            VacationStatus.Rejected,
            VacationStatus.Cancelled
        ],
        [VacationStatus.RejectedAtProjectLevel] = [
            VacationStatus.PendingDepartmentApproval,
            VacationStatus.Approved,
            VacationStatus.Rejected
        ],
        [VacationStatus.Approved] = [VacationStatus.Cancelled],
        [VacationStatus.Rejected] = [],
        [VacationStatus.Cancelled] = []
    };

    private readonly List<StatusTransition> _history = [];
    private readonly List<IDomainEvent> _domainEvents = [];

    public VacationRequestId Id { get; private set; }
    public EmployeeId EmployeeId { get; private set; }
    public DateRange DateRange { get; private set; }
    public VacationStatus Status { get; private set; }
    public EmployeeNotes Notes { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime? LastModifiedAt { get; private set; }
    public IReadOnlyList<StatusTransition> History => _history.AsReadOnly();
    public IReadOnlyList<IDomainEvent> DomainEvents => _domainEvents.AsReadOnly();

    // Required by EF Core
    private VacationRequest()
    {
        DateRange = null!;
        Notes = EmployeeNotes.Empty;
    }

    // INV-001–006 enforced here via BR-001/002
    public static VacationRequest Submit(
        EmployeeId employeeId,
        DateRange dateRange,
        EmployeeNotes notes,
        DateOnly today)
    {
        // INV-001: start date must be >= today + 1 business day (BR-002)
        var minimumStart = NextBusinessDay(today);
        if (dateRange.StartDate < minimumStart)
            throw new DomainException($"Start date must be at least 1 business day in the future. Earliest allowed: {minimumStart}.");

        var request = new VacationRequest
        {
            Id = VacationRequestId.New(),
            EmployeeId = employeeId,
            DateRange = dateRange,
            Status = VacationStatus.Pending,
            Notes = notes,
            CreatedAt = DateTime.UtcNow,
            LastModifiedAt = null
        };

        // INV-006: initial transition always recorded
        var transition = StatusTransition.Create(
            request.Id,
            fromStatus: null,
            VacationStatus.Pending,
            employeeId,
            actorName: "Employee",
            reason: null);

        request._history.Add(transition);

        request._domainEvents.Add(new VacationRequestSubmitted(
            Guid.NewGuid(),
            DateTime.UtcNow,
            request.Id,
            employeeId,
            dateRange,
            dateRange.TotalBusinessDays));

        return request;
    }

    // INV-003/004: only owner can cancel; Cancelled/Rejected are terminal
    public void Cancel(EmployeeId cancelledById)
    {
        // INV-004: cannot cancel already-cancelled or rejected requests
        if (Status is VacationStatus.Cancelled)
            throw new DomainException("Request is already cancelled.");

        if (Status is VacationStatus.Rejected)
            throw new DomainException("A rejected request cannot be cancelled.");

        var previousStatus = Status;
        TransitionTo(VacationStatus.Cancelled, cancelledById, actorName: "Employee", reason: null);

        _domainEvents.Add(new VacationRequestCancelled(
            Guid.NewGuid(),
            DateTime.UtcNow,
            Id,
            EmployeeId,
            cancelledById,
            DateRange,
            previousStatus,
            WasApproved: previousStatus is VacationStatus.Approved));
    }

    // INV-003: only valid state machine transitions are accepted
    public void TransitionTo(
        VacationStatus newStatus,
        EmployeeId changedById,
        string actorName,
        string? reason)
    {
        if (!_allowedTransitions.TryGetValue(Status, out var allowed) || !allowed.Contains(newStatus))
            throw new DomainException($"Transition from {Status} to {newStatus} is not allowed.");

        _history.Add(StatusTransition.Create(Id, Status, newStatus, changedById, actorName, reason));
        Status = newStatus;
        LastModifiedAt = DateTime.UtcNow;
    }

    // INV-002 (BR-004): overlap check — Pending and Approved block new requests
    public bool HasOverlapWith(DateRange other) =>
        Status is VacationStatus.Pending or VacationStatus.Approved or VacationStatus.PendingDepartmentApproval
        && DateRange.OverlapsWith(other);

    public void ClearDomainEvents() => _domainEvents.Clear();

    private static DateOnly NextBusinessDay(DateOnly date)
    {
        var next = date.AddDays(1);
        while (next.DayOfWeek is DayOfWeek.Saturday or DayOfWeek.Sunday)
            next = next.AddDays(1);
        return next;
    }
}
