using ApprovalWorkflow.Domain.ApprovalWorkflows.ValueObjects;
using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;

namespace ApprovalWorkflow.Domain.ApprovalWorkflows;

// INV-110: max one active delegation per delegator per scope
// INV-111: circular delegation not allowed
// INV-112: delegate must be from same project/department (enforced by handler)
// INV-113: EndDate >= StartDate when set
public sealed class Delegation
{
    public DelegationId Id { get; private set; }
    public EmployeeId DelegatorId { get; private set; }
    public EmployeeId DelegateId { get; private set; }
    public DelegationScope Scope { get; private set; }
    public DateOnly StartDate { get; private set; }
    public DateOnly? EndDate { get; private set; }
    public bool IsActive { get; private set; }
    public bool IsRevoked { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime? RevokedAt { get; private set; }
    public EmployeeId? RevokedById { get; private set; }

    private Delegation() { } // EF Core

    public static Delegation Create(
        EmployeeId delegatorId,
        EmployeeId delegateId,
        DelegationScope scope,
        DateOnly startDate,
        DateOnly? endDate)
    {
        // INV-111: circular delegation
        if (delegatorId == delegateId)
            throw new DomainException("Cannot delegate to yourself.");

        // INV-113: end date must not precede start date
        if (endDate.HasValue && endDate.Value < startDate)
            throw new DomainException("End date must be on or after start date (INV-113).");

        return new Delegation
        {
            Id = DelegationId.New(),
            DelegatorId = delegatorId,
            DelegateId = delegateId,
            Scope = scope,
            StartDate = startDate,
            EndDate = endDate,
            IsActive = true,
            IsRevoked = false,
            CreatedAt = DateTime.UtcNow,
            RevokedAt = null,
            RevokedById = null
        };
    }

    // BR-025: permanent delegation remains active until explicitly revoked
    public bool IsPermanent => !EndDate.HasValue;

    // Effective when today falls within [StartDate, EndDate] (or no EndDate)
    public bool IsEffectiveOn(DateOnly date) =>
        IsActive
        && !IsRevoked
        && date >= StartDate
        && (!EndDate.HasValue || date <= EndDate.Value);

    public void Expire()
    {
        IsActive = false;
    }

    public void Revoke(EmployeeId revokedById)
    {
        if (IsRevoked)
            throw new DomainException("Delegation is already revoked.");

        IsRevoked = true;
        IsActive = false;
        RevokedAt = DateTime.UtcNow;
        RevokedById = revokedById;
    }
}
