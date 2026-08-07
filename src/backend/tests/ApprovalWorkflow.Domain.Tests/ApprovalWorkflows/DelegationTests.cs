using ApprovalWorkflow.Domain.ApprovalWorkflows;
using ApprovalWorkflow.Domain.ApprovalWorkflows.ValueObjects;
using FluentAssertions;
using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;
using Xunit;

namespace ApprovalWorkflow.Domain.Tests.ApprovalWorkflows;

// T009: Delegation invariants — circular, one-active, IsEffectiveOn boundaries
public class DelegationTests
{
    private static readonly EmployeeId Delegator = EmployeeId.New();
    private static readonly EmployeeId Delegate_ = EmployeeId.New();
    private static readonly DateOnly Today = new(2026, 8, 7);

    private static Delegation CreateTemporary(
        DateOnly start, DateOnly end,
        EmployeeId? delegator = null, EmployeeId? delegate_ = null) =>
        Delegation.Create(
            delegator ?? Delegator,
            delegate_ ?? Delegate_,
            DelegationScope.ProjectLevel,
            start, end);

    private static Delegation CreatePermanent(
        EmployeeId? delegator = null, EmployeeId? delegate_ = null) =>
        Delegation.Create(
            delegator ?? Delegator,
            delegate_ ?? Delegate_,
            DelegationScope.ProjectLevel,
            Today, endDate: null);

    // ─── INV-111: circular delegation ────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void Create_SamePersonAsDelegatorAndDelegate_ThrowsDomainException()
    {
        var same = EmployeeId.New();
        var act = () => Delegation.Create(same, same, DelegationScope.ProjectLevel, Today, null);
        act.Should().Throw<DomainException>().WithMessage("*delegate to yourself*");
    }

    // ─── INV-113: EndDate >= StartDate ───────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void Create_EndDateBeforeStartDate_ThrowsDomainException()
    {
        var act = () => Delegation.Create(
            Delegator, Delegate_,
            DelegationScope.ProjectLevel,
            new DateOnly(2026, 8, 15),
            new DateOnly(2026, 8, 10));

        act.Should().Throw<DomainException>().WithMessage("*INV-113*");
    }

    // ─── IsEffectiveOn boundaries ─────────────────────────────────────────────

    [Theory]
    [InlineData("2026-08-10", "2026-08-22", "2026-08-09", false)] // before start
    [InlineData("2026-08-10", "2026-08-22", "2026-08-10", true)]  // on start date
    [InlineData("2026-08-10", "2026-08-22", "2026-08-16", true)]  // in middle
    [InlineData("2026-08-10", "2026-08-22", "2026-08-22", true)]  // on end date
    [InlineData("2026-08-10", "2026-08-22", "2026-08-23", false)] // after end
    [Trait("Category", "Unit")]
    public void IsEffectiveOn_TemporaryDelegation_ReturnExpected(
        string start, string end, string checkDate, bool expected)
    {
        var d = CreateTemporary(DateOnly.Parse(start), DateOnly.Parse(end));
        d.IsEffectiveOn(DateOnly.Parse(checkDate)).Should().Be(expected);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void IsEffectiveOn_PermanentDelegation_TrueForAnyFutureDate()
    {
        var d = CreatePermanent();

        d.IsPermanent.Should().BeTrue();
        d.IsEffectiveOn(Today).Should().BeTrue();
        d.IsEffectiveOn(Today.AddYears(5)).Should().BeTrue();
        d.IsEffectiveOn(Today.AddDays(1)).Should().BeTrue();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void IsEffectiveOn_PermanentDelegation_FalseBeforeStart()
    {
        var d = Delegation.Create(Delegator, Delegate_,
            DelegationScope.ProjectLevel,
            startDate: new DateOnly(2026, 8, 15), endDate: null);

        d.IsEffectiveOn(new DateOnly(2026, 8, 14)).Should().BeFalse();
    }

    // ─── Revoke ───────────────────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void Revoke_ActiveDelegation_DeactivatesIt()
    {
        var d = CreatePermanent();

        d.Revoke(Delegator);

        d.IsRevoked.Should().BeTrue();
        d.IsActive.Should().BeFalse();
        d.RevokedAt.Should().NotBeNull();
        d.RevokedById.Should().Be(Delegator);
        d.IsEffectiveOn(Today).Should().BeFalse();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Revoke_AlreadyRevoked_ThrowsDomainException()
    {
        var d = CreatePermanent();
        d.Revoke(Delegator);

        var act = () => d.Revoke(Delegator);
        act.Should().Throw<DomainException>().WithMessage("*already revoked*");
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Expire_ActiveDelegation_DeactivatesWithoutRevoking()
    {
        var d = CreateTemporary(Today, Today.AddDays(7));

        d.Expire();

        d.IsActive.Should().BeFalse();
        d.IsRevoked.Should().BeFalse(); // Expired ≠ Revoked
    }

    // ─── IsEffectiveOn after revoke / expire ──────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void IsEffectiveOn_RevokedDelegation_AlwaysFalse()
    {
        var d = CreatePermanent();
        d.Revoke(Delegator);

        d.IsEffectiveOn(Today).Should().BeFalse();
        d.IsEffectiveOn(Today.AddDays(30)).Should().BeFalse();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void IsEffectiveOn_ExpiredDelegation_AlwaysFalse()
    {
        var d = CreateTemporary(Today, Today.AddDays(7));
        d.Expire();

        d.IsEffectiveOn(Today).Should().BeFalse();
    }

    // ─── Scope ────────────────────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void Create_DepartmentScope_SetsCorrectly()
    {
        var d = Delegation.Create(
            Delegator, Delegate_,
            DelegationScope.DepartmentLevel,
            Today, Today.AddDays(14));

        d.Scope.Should().Be(DelegationScope.DepartmentLevel);
    }

    // ─── EscalationEvent ─────────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void EscalationEvent_Create_SetsNotResolved()
    {
        var wfId = ApprovalWorkflowId.New();
        var reqId = VacationManagement.Domain.VacationRequests.ValueObjects.VacationRequestId.New();

        var ev = EscalationEvent.Create(
            wfId, reqId,
            EscalationType.Reminder,
            ApprovalLevel.Project,
            Delegator);

        ev.IsResolved.Should().BeFalse();
        ev.ResolvedAt.Should().BeNull();
        ev.Type.Should().Be(EscalationType.Reminder);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void EscalationEvent_Resolve_SetsResolvedState()
    {
        var wfId = ApprovalWorkflowId.New();
        var reqId = VacationManagement.Domain.VacationRequests.ValueObjects.VacationRequestId.New();
        var ev = EscalationEvent.Create(wfId, reqId, EscalationType.DirectEscalation, ApprovalLevel.Project, Delegator);

        ev.Resolve();

        ev.IsResolved.Should().BeTrue();
        ev.ResolvedAt.Should().NotBeNull();
    }
}
