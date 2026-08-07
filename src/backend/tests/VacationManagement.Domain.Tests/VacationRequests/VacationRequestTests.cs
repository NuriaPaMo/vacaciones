using FluentAssertions;
using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests;
using VacationManagement.Domain.VacationRequests.Events;
using VacationManagement.Domain.VacationRequests.ValueObjects;
using Xunit;

namespace VacationManagement.Domain.Tests.VacationRequests;

// T008: invariants, state machine, cancel, overlap — covers INV-001–006
public class VacationRequestTests
{
    private static readonly DateOnly Today = new(2026, 8, 7);            // Thursday
    private static readonly EmployeeId Employee = EmployeeId.New();

    private static VacationRequest CreatePending(DateOnly? start = null, DateOnly? end = null)
    {
        var s = start ?? new DateOnly(2026, 8, 10);  // next Monday
        var e = end ?? new DateOnly(2026, 8, 14);
        return VacationRequest.Submit(
            Employee,
            DateRange.Create(s, e),
            EmployeeNotes.Empty,
            Today);
    }

    // ─── Submit / INV-001 ────────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void Submit_WithValidArgs_CreatesPendingRequest()
    {
        var request = CreatePending();

        request.Status.Should().Be(VacationStatus.Pending);
        request.History.Should().HaveCount(1);
        request.History[0].FromStatus.Should().BeNull();
        request.History[0].ToStatus.Should().Be(VacationStatus.Pending);
        request.DomainEvents.Should().ContainSingle(e => e is VacationRequestSubmitted);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Submit_WhenStartDateIsToday_ThrowsDomainException()
    {
        // INV-001 / BR-002: start must be ≥ tomorrow (1 business day ahead)
        var act = () => VacationRequest.Submit(
            Employee,
            DateRange.Create(Today, Today.AddDays(5)),
            EmployeeNotes.Empty,
            Today);

        act.Should().Throw<DomainException>();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Submit_WhenStartIsNextBusinessDay_Succeeds()
    {
        // Friday today → next business day is Monday
        var friday = new DateOnly(2026, 8, 7);
        var monday = new DateOnly(2026, 8, 10);

        var request = VacationRequest.Submit(
            Employee,
            DateRange.Create(monday, monday.AddDays(4)),
            EmployeeNotes.Empty,
            friday);

        request.Status.Should().Be(VacationStatus.Pending);
    }

    // ─── State Machine ────────────────────────────────────────────────────────

    [Theory]
    [InlineData(VacationStatus.Pending, VacationStatus.PendingDepartmentApproval)]
    [InlineData(VacationStatus.Pending, VacationStatus.RejectedAtProjectLevel)]
    [InlineData(VacationStatus.Pending, VacationStatus.Cancelled)]
    [Trait("Category", "Unit")]
    public void TransitionTo_AllowedFromPending_Succeeds(VacationStatus from, VacationStatus to)
    {
        var request = CreatePending();
        from.Should().Be(request.Status); // assert starting state

        var act = () => request.TransitionTo(to, Employee, "Actor", reason: to == VacationStatus.RejectedAtProjectLevel ? "Coverage gap issue" : null);
        act.Should().NotThrow();
        request.Status.Should().Be(to);
    }

    [Theory]
    [InlineData(VacationStatus.Pending, VacationStatus.Approved)]
    [InlineData(VacationStatus.Pending, VacationStatus.Rejected)]
    [Trait("Category", "Unit")]
    public void TransitionTo_ForbiddenFromPending_ThrowsDomainException(VacationStatus _, VacationStatus to)
    {
        var request = CreatePending();

        var act = () => request.TransitionTo(to, Employee, "Actor", reason: null);
        act.Should().Throw<DomainException>();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void TransitionTo_FromApproved_OnlyCancelledAllowed()
    {
        var request = CreatePending();
        request.TransitionTo(VacationStatus.PendingDepartmentApproval, Employee, "PM", null);
        request.TransitionTo(VacationStatus.Approved, Employee, "DM", null);

        request.TransitionTo(VacationStatus.Cancelled, Employee, "Employee", null);
        request.Status.Should().Be(VacationStatus.Cancelled);
    }

    [Theory]
    [InlineData(VacationStatus.Cancelled)]
    [InlineData(VacationStatus.Rejected)]
    [Trait("Category", "Unit")]
    public void TransitionTo_FromTerminalState_ThrowsDomainException(VacationStatus terminal)
    {
        var request = CreatePending();
        if (terminal == VacationStatus.Cancelled)
            request.Cancel(Employee);
        else
        {
            request.TransitionTo(VacationStatus.PendingDepartmentApproval, Employee, "PM", null);
            request.TransitionTo(VacationStatus.Rejected, Employee, "DM", "Cannot approve in peak period");
        }

        var act = () => request.TransitionTo(VacationStatus.Pending, Employee, "Actor", null);
        act.Should().Throw<DomainException>();
    }

    // ─── Cancel ───────────────────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void Cancel_PendingRequest_SetsStatusAndRaisesEvent()
    {
        var request = CreatePending();
        request.Cancel(Employee);

        request.Status.Should().Be(VacationStatus.Cancelled);
        request.DomainEvents.OfType<VacationRequestCancelled>().Should().ContainSingle();
        var ev = request.DomainEvents.OfType<VacationRequestCancelled>().Single();
        ev.WasApproved.Should().BeFalse();
        ev.PreviousStatus.Should().Be(VacationStatus.Pending);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Cancel_ApprovedRequest_SetsWasApprovedTrue()
    {
        var request = CreatePending();
        request.TransitionTo(VacationStatus.PendingDepartmentApproval, Employee, "PM", null);
        request.TransitionTo(VacationStatus.Approved, Employee, "DM", null);

        request.Cancel(Employee);

        var ev = request.DomainEvents.OfType<VacationRequestCancelled>().Single();
        ev.WasApproved.Should().BeTrue();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Cancel_AlreadyCancelledRequest_ThrowsDomainException()
    {
        var request = CreatePending();
        request.Cancel(Employee);

        var act = () => request.Cancel(Employee);
        act.Should().Throw<DomainException>();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Cancel_RejectedRequest_ThrowsDomainException()
    {
        var request = CreatePending();
        request.TransitionTo(VacationStatus.PendingDepartmentApproval, Employee, "PM", null);
        request.TransitionTo(VacationStatus.Rejected, Employee, "DM", "Department coverage requirement");

        var act = () => request.Cancel(Employee);
        act.Should().Throw<DomainException>();
    }

    // ─── HasOverlapWith (INV-002 / BR-004) ────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void HasOverlapWith_PendingAndOverlapping_ReturnsTrue()
    {
        var request = CreatePending(new DateOnly(2026, 8, 10), new DateOnly(2026, 8, 14));
        var other = DateRange.Create(new DateOnly(2026, 8, 12), new DateOnly(2026, 8, 16));

        request.HasOverlapWith(other).Should().BeTrue();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void HasOverlapWith_PendingAndNonOverlapping_ReturnsFalse()
    {
        var request = CreatePending(new DateOnly(2026, 8, 10), new DateOnly(2026, 8, 14));
        var other = DateRange.Create(new DateOnly(2026, 8, 17), new DateOnly(2026, 8, 21));

        request.HasOverlapWith(other).Should().BeFalse();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void HasOverlapWith_CancelledAndOverlapping_ReturnsFalse()
    {
        var request = CreatePending(new DateOnly(2026, 8, 10), new DateOnly(2026, 8, 14));
        request.Cancel(Employee);

        var other = DateRange.Create(new DateOnly(2026, 8, 12), new DateOnly(2026, 8, 16));
        request.HasOverlapWith(other).Should().BeFalse(); // Cancelled does not block
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void HasOverlapWith_RejectedAndOverlapping_ReturnsFalse()
    {
        var request = CreatePending(new DateOnly(2026, 8, 10), new DateOnly(2026, 8, 14));
        request.TransitionTo(VacationStatus.PendingDepartmentApproval, Employee, "PM", null);
        request.TransitionTo(VacationStatus.Rejected, Employee, "DM", "Cannot allow due to project deadline");

        var other = DateRange.Create(new DateOnly(2026, 8, 12), new DateOnly(2026, 8, 16));
        request.HasOverlapWith(other).Should().BeFalse(); // Rejected does not block
    }

    // ─── StatusTransition validation ─────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void TransitionTo_RejectWithShortReason_ThrowsDomainException()
    {
        var request = CreatePending();
        var act = () => request.TransitionTo(
            VacationStatus.RejectedAtProjectLevel, Employee, "PM", reason: "Too short");

        act.Should().Throw<DomainException>().WithMessage("*10 characters*");
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void TransitionTo_RejectWithNoReason_ThrowsDomainException()
    {
        var request = CreatePending();
        request.TransitionTo(VacationStatus.PendingDepartmentApproval, Employee, "PM", null);

        var act = () => request.TransitionTo(
            VacationStatus.Rejected, Employee, "DM", reason: null);

        act.Should().Throw<DomainException>().WithMessage("*reason is required*");
    }

    // ─── History integrity ────────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void History_AfterMultipleTransitions_RecordsAllInOrder()
    {
        var request = CreatePending();
        request.TransitionTo(VacationStatus.PendingDepartmentApproval, Employee, "PM", null);
        request.TransitionTo(VacationStatus.Approved, Employee, "DM", null);

        request.History.Should().HaveCount(3);
        request.History[0].ToStatus.Should().Be(VacationStatus.Pending);
        request.History[1].ToStatus.Should().Be(VacationStatus.PendingDepartmentApproval);
        request.History[2].ToStatus.Should().Be(VacationStatus.Approved);
    }
}
