using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;

namespace VacationManagement.Domain.VacationRequests.Events;

public sealed record VacationRequestSubmitted(
    Guid EventId,
    DateTime OccurredOn,
    VacationRequestId RequestId,
    EmployeeId EmployeeId,
    DateRange DateRange,
    int TotalBusinessDays) : IDomainEvent;
