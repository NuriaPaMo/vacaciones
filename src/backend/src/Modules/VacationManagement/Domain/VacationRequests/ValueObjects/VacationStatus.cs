namespace VacationManagement.Domain.VacationRequests.ValueObjects;

public enum VacationStatus
{
    Pending,
    PendingDepartmentApproval,
    RejectedAtProjectLevel,
    Approved,
    Rejected,
    Cancelled
}
