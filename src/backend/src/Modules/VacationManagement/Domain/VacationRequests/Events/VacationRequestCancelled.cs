using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;

namespace VacationManagement.Domain.VacationRequests.Events;

public sealed record VacationRequestCancelled(
    Guid EventId,
    DateTime OccurredOn,
    VacationRequestId RequestId,
    EmployeeId EmployeeId,
    EmployeeId CancelledByEmployeeId,
    DateRange DateRange,
    VacationStatus PreviousStatus,
    bool WasApproved) : IDomainEvent;
