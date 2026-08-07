using ApprovalWorkflow.Domain.ApprovalWorkflows;
using ApprovalWorkflow.Domain.ApprovalWorkflows.Events;
using ApprovalWorkflow.Domain.ApprovalWorkflows.ValueObjects;
using FluentAssertions;
using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;
using Xunit;

namespace ApprovalWorkflow.Domain.Tests.ApprovalWorkflows;

// T008: state machine — 11 allowed transitions, forbidden transitions, self-approval (BR-019a)
public class ApprovalWorkflowTests
{
    private static readonly VacationRequestId RequestId = VacationRequestId.New();
    private static readonly EmployeeId Pm = EmployeeId.New();
    private static readonly EmployeeId Dm = EmployeeId.New();

    private static Domain.ApprovalWorkflows.ApprovalWorkflow Create() =>
        Domain.ApprovalWorkflows.ApprovalWorkflow.Create(RequestId);

    // ─── Happy path ──────────────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void Create_SetsProjectLevelAndNotCompleted()
    {
        var wf = Create();

        wf.CurrentLevel.Should().Be(ApprovalLevel.Project);
        wf.IsCompleted().Should().BeFalse();
        wf.Steps.Should().BeEmpty();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void FullApprovalPath_ProjectThenDept_CompletesWorkflow()
    {
        var wf = Create();

        wf.ApproveAtProjectLevel(Pm, "Carlos Ruiz");
        wf.CurrentLevel.Should().Be(ApprovalLevel.Department);
        wf.IsCompleted().Should().BeFalse();

        wf.ApproveAtDepartmentLevel(Dm, "Laura Sánchez");
        wf.IsCompleted().Should().BeTrue();
        wf.CompletedAt.Should().NotBeNull();
        wf.Steps.Should().HaveCount(2);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void FullRejectionPath_ProjectThenDept_Completes()
    {
        var wf = Create();

        wf.RejectAtProjectLevel(Pm, "Carlos Ruiz", "Coverage gap during sprint deadline");
        wf.MoveToDepartmentQueue(); // employee appeals
        wf.RejectAtDepartmentLevel(Dm, "Laura Sánchez", "Confirmed peak period restriction");

        wf.IsCompleted().Should().BeTrue();
        wf.Steps.Should().HaveCount(2);
    }

    // ─── Rejection not final at project level (BR-016) ───────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void RejectAtProjectLevel_WorkflowNotCompleted_EmployeeCanAppeal()
    {
        var wf = Create();
        wf.RejectAtProjectLevel(Pm, "Carlos Ruiz", "Coverage gap — sprint deadline conflicts");

        wf.IsCompleted().Should().BeFalse(); // NOT final
        wf.DomainEvents.Should().ContainSingle(e => e is VacationRequestRejectedAtProjectLevel);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void MoveToDepartmentQueue_AfterProjectRejection_AllowsDMToAct()
    {
        var wf = Create();
        wf.RejectAtProjectLevel(Pm, "Carlos Ruiz", "Coverage gap — sprint deadline conflicts");
        wf.MoveToDepartmentQueue();

        wf.CurrentLevel.Should().Be(ApprovalLevel.Department);
        wf.ApproveAtDepartmentLevel(Dm, "Laura Sánchez"); // DM overrides PM rejection
        wf.IsCompleted().Should().BeTrue();
    }

    // ─── Direct escalation bypass (AC-007.3) ─────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void MoveToDepartmentQueue_FromProject_DmCanBypassPm()
    {
        var wf = Create();
        wf.MoveToDepartmentQueue(); // EscalationService moves it directly

        wf.CurrentLevel.Should().Be(ApprovalLevel.Department);
        wf.ApproveAtDepartmentLevel(Dm, "Laura Sánchez");
        wf.IsCompleted().Should().BeTrue();
    }

    // ─── Delegate flag propagation ────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void ApproveAtProjectLevel_WithDelegate_RecordsOriginalApprover()
    {
        var wf = Create();
        var originalPm = EmployeeId.New();

        wf.ApproveAtProjectLevel(
            approverId: Pm,
            approverName: "María Fernández",
            originalApproverId: originalPm,
            originalApproverName: "Carlos Ruiz");

        var step = wf.Steps.Single();
        step.IsDelegate.Should().BeTrue();
        step.OriginalApproverId.Should().Be(originalPm);
    }

    // ─── INV-101: completed workflow is immutable ─────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void ApproveAtProjectLevel_WhenCompleted_ThrowsDomainException()
    {
        var wf = Create();
        wf.ApproveAtProjectLevel(Pm, "Carlos Ruiz");
        wf.ApproveAtDepartmentLevel(Dm, "Laura Sánchez");

        var act = () => wf.ApproveAtProjectLevel(Pm, "Carlos Ruiz");
        act.Should().Throw<DomainException>().WithMessage("*already completed*");
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void RejectAtDepartmentLevel_WhenCompleted_ThrowsDomainException()
    {
        var wf = Create();
        wf.ApproveAtProjectLevel(Pm, "Carlos Ruiz");
        wf.ApproveAtDepartmentLevel(Dm, "Laura Sánchez");

        var act = () => wf.RejectAtDepartmentLevel(Dm, "Laura Sánchez", "Cannot reject already completed");
        act.Should().Throw<DomainException>();
    }

    // ─── INV-103: level enforcement ──────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void ApproveAtDepartmentLevel_WhenAtProjectLevel_ThrowsDomainException()
    {
        var wf = Create();

        var act = () => wf.ApproveAtDepartmentLevel(Dm, "Laura Sánchez");
        act.Should().Throw<DomainException>().WithMessage("*Department level*");
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void ApproveAtProjectLevel_WhenAtDepartmentLevel_ThrowsDomainException()
    {
        var wf = Create();
        wf.ApproveAtProjectLevel(Pm, "Carlos Ruiz");

        var act = () => wf.ApproveAtProjectLevel(Pm, "Carlos Ruiz");
        act.Should().Throw<DomainException>().WithMessage("*Project level*");
    }

    // ─── INV-103: reason enforcement ─────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void RejectAtProjectLevel_WithNoReason_ThrowsDomainException()
    {
        var wf = Create();

        var act = () => wf.RejectAtProjectLevel(Pm, "Carlos Ruiz", reason: null!);
        act.Should().Throw<DomainException>().WithMessage("*reason is required*");
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void RejectAtProjectLevel_WithShortReason_ThrowsDomainException()
    {
        var wf = Create();

        var act = () => wf.RejectAtProjectLevel(Pm, "Carlos Ruiz", reason: "Too short");
        act.Should().Throw<DomainException>().WithMessage("*10 characters*");
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void RejectAtDepartmentLevel_WithNoReason_ThrowsDomainException()
    {
        var wf = Create();
        wf.ApproveAtProjectLevel(Pm, "Carlos Ruiz");

        var act = () => wf.RejectAtDepartmentLevel(Dm, "Laura Sánchez", reason: null!);
        act.Should().Throw<DomainException>().WithMessage("*reason is required*");
    }

    // ─── Escalation recording ────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void RecordEscalation_Reminder_PublishesDomainEvent()
    {
        var wf = Create();
        wf.RecordEscalation(EscalationType.Reminder, Pm);

        wf.DomainEvents.Should().ContainSingle(e => e is ApprovalEscalationTriggered);
        var ev = (ApprovalEscalationTriggered)wf.DomainEvents.Single(e => e is ApprovalEscalationTriggered);
        ev.EscalationType.Should().Be(EscalationType.Reminder);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void RecordEscalation_DirectEscalation_PublishesDomainEvent()
    {
        var wf = Create();
        wf.RecordEscalation(EscalationType.DirectEscalation, Dm);

        var ev = (ApprovalEscalationTriggered)wf.DomainEvents.Single(e => e is ApprovalEscalationTriggered);
        ev.EscalationType.Should().Be(EscalationType.DirectEscalation);
    }

    // ─── Domain event integrity ───────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void ApproveAtDepartmentLevel_PublishesApprovedFinalEvent()
    {
        var wf = Create();
        wf.ApproveAtProjectLevel(Pm, "Carlos Ruiz");
        wf.ApproveAtDepartmentLevel(Dm, "Laura Sánchez");

        wf.DomainEvents.Should().Contain(e => e is VacationRequestApprovedFinal);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void ClearDomainEvents_RemovesAll()
    {
        var wf = Create();
        wf.ApproveAtProjectLevel(Pm, "Carlos Ruiz");

        wf.ClearDomainEvents();
        wf.DomainEvents.Should().BeEmpty();
    }

    // ─── MarkCancelledByEmployee ──────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void MarkCancelledByEmployee_CompletesWorkflow()
    {
        var wf = Create();
        wf.MarkCancelledByEmployee();

        wf.IsCompleted().Should().BeTrue();
    }

    // ─── EscalationThreshold (BR-034) ────────────────────────────────────────

    [Theory]
    [InlineData(2, false, false)]
    [InlineData(3, true, false)]
    [InlineData(4, true, false)]
    [InlineData(5, true, true)]
    [InlineData(10, true, true)]
    [Trait("Category", "Unit")]
    public void EscalationThreshold_Default_EvaluatesCorrectly(
        int days, bool expectedReminder, bool expectedEscalate)
    {
        var threshold = EscalationThreshold.Default;

        threshold.ShouldSendReminder(days).Should().Be(expectedReminder);
        threshold.ShouldEscalate(days).Should().Be(expectedEscalate);
    }
}
