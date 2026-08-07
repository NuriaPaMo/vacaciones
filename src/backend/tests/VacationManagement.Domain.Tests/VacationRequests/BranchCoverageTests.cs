using FluentAssertions;
using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests;
using VacationManagement.Domain.VacationRequests.ValueObjects;
using Xunit;

namespace VacationManagement.Domain.Tests.VacationRequests;

// Covers branches missed in T007/T008 to push branch coverage ≥ 75%
public class BranchCoverageTests
{
    private static readonly DateOnly Today = new(2026, 8, 7);
    private static readonly EmployeeId Employee = EmployeeId.New();

    // ─── EmployeeNotes branches ──────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void EmployeeNotes_Create_WithNull_ReturnsEmpty()
    {
        var notes = EmployeeNotes.Create(null);
        notes.IsEmpty.Should().BeTrue();
        notes.Value.Should().BeNull();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void EmployeeNotes_Create_WithWhitespaceOnly_ReturnsEmpty()
    {
        var notes = EmployeeNotes.Create("   ");
        notes.IsEmpty.Should().BeTrue();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void EmployeeNotes_Create_WithMaxLengthPlusOne_ThrowsDomainException()
    {
        var tooLong = new string('x', EmployeeNotes.MaxLength + 1);
        var act = () => EmployeeNotes.Create(tooLong);
        act.Should().Throw<DomainException>();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void EmployeeNotes_Equals_SameValue_ReturnsTrue()
    {
        var a = EmployeeNotes.Create("Summer trip");
        var b = EmployeeNotes.Create("Summer trip");
        a.Should().Be(b);
        a.GetHashCode().Should().Be(b.GetHashCode());
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void EmployeeNotes_Empty_EqualsItself()
    {
        EmployeeNotes.Empty.Should().BeSameAs(EmployeeNotes.Empty);
        EmployeeNotes.Empty.ToString().Should().BeEmpty();
    }

    // ─── VacationRequest — RejectedAtProjectLevel paths ─────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void TransitionTo_FromRejectedAtProjectLevel_ToDMApproval_Succeeds()
    {
        var request = VacationRequest.Submit(
            Employee,
            DateRange.Create(new DateOnly(2026, 8, 10), new DateOnly(2026, 8, 14)),
            EmployeeNotes.Empty, Today);

        request.TransitionTo(VacationStatus.RejectedAtProjectLevel, Employee, "PM", "Coverage gap in sprint");
        request.TransitionTo(VacationStatus.PendingDepartmentApproval, Employee, "Employee", null);

        request.Status.Should().Be(VacationStatus.PendingDepartmentApproval);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void TransitionTo_FromRejectedAtProjectLevel_DMOverride_Succeeds()
    {
        var request = VacationRequest.Submit(
            Employee,
            DateRange.Create(new DateOnly(2026, 8, 10), new DateOnly(2026, 8, 14)),
            EmployeeNotes.Empty, Today);

        request.TransitionTo(VacationStatus.RejectedAtProjectLevel, Employee, "PM", "Coverage gap in sprint");
        request.TransitionTo(VacationStatus.Approved, Employee, "DM", null);

        request.Status.Should().Be(VacationStatus.Approved);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void TransitionTo_FromRejectedAtProjectLevel_DMConfirms_Succeeds()
    {
        var request = VacationRequest.Submit(
            Employee,
            DateRange.Create(new DateOnly(2026, 8, 10), new DateOnly(2026, 8, 14)),
            EmployeeNotes.Empty, Today);

        request.TransitionTo(VacationStatus.RejectedAtProjectLevel, Employee, "PM", "Coverage gap in sprint");
        request.TransitionTo(VacationStatus.Rejected, Employee, "DM", "Confirmed — peak period restriction");

        request.Status.Should().Be(VacationStatus.Rejected);
    }

    // ─── HasOverlapWith — Approved state blocks ──────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void HasOverlapWith_ApprovedRequest_BlocksNewOverlap()
    {
        var request = VacationRequest.Submit(
            Employee,
            DateRange.Create(new DateOnly(2026, 8, 10), new DateOnly(2026, 8, 14)),
            EmployeeNotes.Empty, Today);

        request.TransitionTo(VacationStatus.PendingDepartmentApproval, Employee, "PM", null);
        request.TransitionTo(VacationStatus.Approved, Employee, "DM", null);

        var overlap = DateRange.Create(new DateOnly(2026, 8, 12), new DateOnly(2026, 8, 16));
        request.HasOverlapWith(overlap).Should().BeTrue();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void HasOverlapWith_PendingDeptApproval_BlocksOverlap()
    {
        var request = VacationRequest.Submit(
            Employee,
            DateRange.Create(new DateOnly(2026, 8, 10), new DateOnly(2026, 8, 14)),
            EmployeeNotes.Empty, Today);

        request.TransitionTo(VacationStatus.PendingDepartmentApproval, Employee, "PM", null);

        var overlap = DateRange.Create(new DateOnly(2026, 8, 12), new DateOnly(2026, 8, 16));
        request.HasOverlapWith(overlap).Should().BeTrue();
    }

    // ─── DomainEvents lifecycle ───────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void ClearDomainEvents_RemovesAllEvents()
    {
        var request = VacationRequest.Submit(
            Employee,
            DateRange.Create(new DateOnly(2026, 8, 10), new DateOnly(2026, 8, 14)),
            EmployeeNotes.Empty, Today);

        request.DomainEvents.Should().NotBeEmpty();
        request.ClearDomainEvents();
        request.DomainEvents.Should().BeEmpty();
    }

    // ─── StatusTransition edge cases ─────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void StatusTransition_Rejection_WithValidReason_Recorded()
    {
        var request = VacationRequest.Submit(
            Employee,
            DateRange.Create(new DateOnly(2026, 8, 10), new DateOnly(2026, 8, 14)),
            EmployeeNotes.Empty, Today);

        request.TransitionTo(
            VacationStatus.PendingDepartmentApproval, Employee, "PM", null);
        request.TransitionTo(
            VacationStatus.Rejected, Employee, "DM", "Cannot approve — summer peak restriction");

        var rejection = request.History.Last();
        rejection.Reason.Should().NotBeNullOrWhiteSpace();
        rejection.ToStatus.Should().Be(VacationStatus.Rejected);
    }
}
