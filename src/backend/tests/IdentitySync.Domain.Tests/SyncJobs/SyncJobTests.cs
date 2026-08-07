using FluentAssertions;
using IdentitySync.Domain.SyncJobs;
using VacationManagement.Domain.Common;
using Xunit;

namespace IdentitySync.Domain.Tests.SyncJobs;

// T009: SyncJob status transitions, RecordError, Complete, Fail, Duration, ExceedsErrorThreshold
public class SyncJobTests
{
    // ─── Start ────────────────────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void Start_Scheduled_CreatesRunningJob()
    {
        var job = SyncJob.Start(SyncJobType.Scheduled);

        job.Status.Should().Be(SyncJobStatus.Running);
        job.Type.Should().Be(SyncJobType.Scheduled);
        job.ErrorCount.Should().Be(0);
        job.Errors.Should().BeEmpty();
        job.CompletedAt.Should().BeNull();
        job.IsTerminal().Should().BeFalse();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Start_Manual_RecordsTriggeredBy()
    {
        var job = SyncJob.Start(SyncJobType.Manual, triggeredBy: "admin@company.com");
        job.TriggeredBy.Should().Be("admin@company.com");
    }

    // ─── RecordError ─────────────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void RecordError_IncrementsErrorCount()
    {
        var job = SyncJob.Start(SyncJobType.Scheduled);
        job.RecordError("user-001", "API timeout", retryCount: 2);
        job.RecordError("user-002", "Not found", retryCount: 1);

        job.ErrorCount.Should().Be(2);
        job.Errors.Should().HaveCount(2);
        job.Errors[0].EmployeeExternalId.Should().Be("user-001");
        job.Errors[0].RetryCount.Should().Be(2);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void RecordError_WhenTerminal_ThrowsDomainException()
    {
        var job = SyncJob.Start(SyncJobType.Scheduled);
        job.Complete(10, 5, 5, 0);

        var act = () => job.RecordError("user-001", "Late error", 0);
        act.Should().Throw<DomainException>().WithMessage("*INV-303*");
    }

    // ─── Complete ─────────────────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void Complete_WithNoErrors_SetsCompletedStatus()
    {
        var job = SyncJob.Start(SyncJobType.Scheduled);
        job.Complete(500, 10, 480, 10);

        job.Status.Should().Be(SyncJobStatus.Completed);
        job.TotalProcessed.Should().Be(500);
        job.Created.Should().Be(10);
        job.Updated.Should().Be(480);
        job.Deactivated.Should().Be(10);
        job.CompletedAt.Should().NotBeNull();
        job.IsTerminal().Should().BeTrue();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Complete_WithErrors_SetsCompletedWithErrorsStatus()
    {
        var job = SyncJob.Start(SyncJobType.Scheduled);
        job.RecordError("user-001", "Timeout", 3);
        job.Complete(100, 50, 49, 0);

        job.Status.Should().Be(SyncJobStatus.CompletedWithErrors);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Complete_WhenAlreadyTerminal_ThrowsDomainException()
    {
        var job = SyncJob.Start(SyncJobType.Scheduled);
        job.Complete(10, 5, 5, 0);

        var act = () => job.Complete(10, 5, 5, 0);
        act.Should().Throw<DomainException>();
    }

    // ─── Fail ─────────────────────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void Fail_SetsFailedStatus()
    {
        var job = SyncJob.Start(SyncJobType.Scheduled);
        job.Fail("Graph API unavailable");

        job.Status.Should().Be(SyncJobStatus.Failed);
        job.IsTerminal().Should().BeTrue();
        job.CompletedAt.Should().NotBeNull();
        job.Errors.Should().ContainSingle(e => e.ErrorMessage == "Graph API unavailable");
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Fail_WhenAlreadyTerminal_ThrowsDomainException()
    {
        var job = SyncJob.Start(SyncJobType.Scheduled);
        job.Fail("First failure");

        var act = () => job.Fail("Second failure");
        act.Should().Throw<DomainException>();
    }

    // ─── Duration ─────────────────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void Duration_WhenRunning_ReturnsNull()
    {
        var job = SyncJob.Start(SyncJobType.Scheduled);
        job.Duration().Should().BeNull();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Duration_WhenCompleted_ReturnsPositiveTimeSpan()
    {
        var job = SyncJob.Start(SyncJobType.Scheduled);
        job.Complete(10, 5, 5, 0);

        job.Duration().Should().NotBeNull();
        job.Duration()!.Value.Should().BeGreaterThanOrEqualTo(TimeSpan.Zero);
    }

    // ─── ExceedsErrorThreshold (BR-069: >5%) ─────────────────────────────────

    [Theory]
    [InlineData(100, 5, false)]   // exactly 5% = does not exceed
    [InlineData(100, 6, true)]    // 6% > 5% = exceeds
    [InlineData(0, 0, false)]     // no processing = no alert
    [InlineData(10, 1, true)]     // 1/10 = 10% > 5% = exceeds
    [InlineData(20, 1, false)]    // 1/20 = 5% = does not exceed
    [Trait("Category", "Unit")]
    public void ExceedsErrorThreshold_ReturnsExpected(
        int totalProcessed, int errorCount, bool expected)
    {
        var job = SyncJob.Start(SyncJobType.Scheduled);
        for (var i = 0; i < errorCount; i++)
            job.RecordError($"user-{i}", "Error", 0);
        job.Complete(totalProcessed, 0, totalProcessed - errorCount, 0);

        job.ExceedsErrorThreshold().Should().Be(expected);
    }
}
