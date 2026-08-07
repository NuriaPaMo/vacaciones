using FluentAssertions;
using ServiceNowIntegration.Domain.Exports;
using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;
using Xunit;

namespace ServiceNowIntegration.Domain.Tests.Exports;

// T009: ExportJob aggregate — RecordSuccess, RecordFailure, Complete, Fail, terminal state
// T010: ExportRecord.Retry() — returns false at RetryCount = 3
public class ExportJobTests
{
    private static readonly VacationRequestId RequestId = VacationRequestId.New();

    // ─── ExportJob.Start ─────────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void Start_CreatesRunningJob_WithZeroCounts()
    {
        var job = ExportJob.Start();

        job.Status.Should().Be(ExportJobStatus.Running);
        job.TotalExported.Should().Be(0);
        job.ErrorCount.Should().Be(0);
        job.Records.Should().BeEmpty();
        job.IsTerminal().Should().BeFalse();
    }

    // ─── AddRecord ────────────────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void AddRecord_ReturnsNewPendingRecord()
    {
        var job = ExportJob.Start();
        var record = job.AddRecord(RequestId, ExportAction.Create);

        record.Status.Should().Be(ExportRecordStatus.Pending);
        record.Action.Should().Be(ExportAction.Create);
        record.RetryCount.Should().Be(0);
        job.Records.Should().HaveCount(1);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void AddRecord_WhenCompleted_ThrowsDomainException()
    {
        var job = ExportJob.Start();
        job.Complete();

        var act = () => job.AddRecord(RequestId, ExportAction.Create);
        act.Should().Throw<DomainException>();
    }

    // ─── RecordSuccess ────────────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void RecordSuccess_Create_IncrementsTotalExported()
    {
        var job = ExportJob.Start();
        var record = job.AddRecord(RequestId, ExportAction.Create);

        job.RecordSuccess(record.Id, "SYS001");

        job.TotalExported.Should().Be(1);
        job.TotalUpdated.Should().Be(0);
        job.TotalDeleted.Should().Be(0);
        record.Status.Should().Be(ExportRecordStatus.Succeeded);
        record.ServiceNowRecordId.Should().Be("SYS001");
        record.ExportedAt.Should().NotBeNull();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void RecordSuccess_Delete_IncrementsTotalDeleted()
    {
        var job = ExportJob.Start();
        var record = job.AddRecord(RequestId, ExportAction.Delete);

        job.RecordSuccess(record.Id, "SYS001");

        job.TotalDeleted.Should().Be(1);
        job.TotalExported.Should().Be(0);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void RecordSuccess_Update_IncrementsTotalUpdated()
    {
        var job = ExportJob.Start();
        var record = job.AddRecord(RequestId, ExportAction.Update);

        job.RecordSuccess(record.Id, "SYS001");

        job.TotalUpdated.Should().Be(1);
    }

    // ─── RecordFailure ────────────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void RecordFailure_IncrementsErrorCount()
    {
        var job = ExportJob.Start();
        var record = job.AddRecord(RequestId, ExportAction.Create);

        job.RecordFailure(record.Id, "API timeout");

        job.ErrorCount.Should().Be(1);
        record.Status.Should().Be(ExportRecordStatus.Failed);
        record.RetryCount.Should().Be(1);
        record.ErrorMessage.Should().Be("API timeout");
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void RecordFailure_NotFoundRecord_ThrowsDomainException()
    {
        var job = ExportJob.Start();

        var act = () => job.RecordFailure(Guid.NewGuid(), "Not found");
        act.Should().Throw<DomainException>();
    }

    // ─── Complete ─────────────────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void Complete_NoErrors_SetsCompletedStatus()
    {
        var job = ExportJob.Start();
        var r = job.AddRecord(RequestId, ExportAction.Create);
        job.RecordSuccess(r.Id, "SYS001");

        job.Complete();

        job.Status.Should().Be(ExportJobStatus.Completed);
        job.CompletedAt.Should().NotBeNull();
        job.IsTerminal().Should().BeTrue();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Complete_WithErrors_SetsCompletedWithErrorsStatus()
    {
        var job = ExportJob.Start();
        var r = job.AddRecord(RequestId, ExportAction.Create);
        job.RecordFailure(r.Id, "Error");

        job.Complete();

        job.Status.Should().Be(ExportJobStatus.CompletedWithErrors);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Complete_WhenAlreadyTerminal_ThrowsDomainException()
    {
        var job = ExportJob.Start();
        job.Complete();

        var act = () => job.Complete();
        act.Should().Throw<DomainException>();
    }

    // ─── ExceedsErrorThreshold (BR-081: >5%) ─────────────────────────────────

    [Theory]
    [InlineData(20, 1, false)]  // 1/20 = 5% — not exceeded
    [InlineData(20, 2, true)]   // 2/20 = 10% > 5% — exceeded
    [InlineData(0, 0, false)]   // empty batch
    [InlineData(100, 5, false)] // exactly 5% — not exceeded
    [InlineData(100, 6, true)]  // 6% > 5% — exceeded
    [Trait("Category", "Unit")]
    public void ExceedsErrorThreshold_ReturnsExpected(
        int total, int failureCount, bool expected)
    {
        var job = ExportJob.Start();
        for (var i = 0; i < total; i++)
        {
            var reqId = VacationRequestId.New();
            var r = job.AddRecord(reqId, ExportAction.Create);
            if (i < total - failureCount)
                job.RecordSuccess(r.Id, $"SYS{i:D3}");
            else
                job.RecordFailure(r.Id, "Error");
        }

        job.ExceedsErrorThreshold().Should().Be(expected);
    }

    // ─── ExportRecord.Retry (T010) ────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void Retry_BeforeMaxRetries_ReturnsTrue_AndResetsToPending()
    {
        var job = ExportJob.Start();
        var r = job.AddRecord(RequestId, ExportAction.Create);

        job.RecordFailure(r.Id, "Error 1"); // RetryCount = 1 → Failed
        job.RecordFailure(r.Id, "Error 2"); // RetryCount = 2 → Failed

        r.Retry().Should().BeTrue();
        r.Status.Should().Be(ExportRecordStatus.Pending);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void ExportRecord_AfterThreeFailures_SetsMaxRetriesExceeded()
    {
        var job = ExportJob.Start();
        var r = job.AddRecord(RequestId, ExportAction.Create);

        job.RecordFailure(r.Id, "Error 1"); // RetryCount = 1
        job.RecordFailure(r.Id, "Error 2"); // RetryCount = 2
        job.RecordFailure(r.Id, "Error 3"); // RetryCount = 3 → MaxRetriesExceeded

        r.Status.Should().Be(ExportRecordStatus.MaxRetriesExceeded);
        r.RetryCount.Should().Be(3);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Retry_AtMaxRetries_ReturnsFalse()
    {
        var job = ExportJob.Start();
        var r = job.AddRecord(RequestId, ExportAction.Create);

        job.RecordFailure(r.Id, "E1");
        job.RecordFailure(r.Id, "E2");
        job.RecordFailure(r.Id, "E3"); // MaxRetriesExceeded

        r.Retry().Should().BeFalse();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void AdminReset_ResetsCounterAndStatus()
    {
        var job = ExportJob.Start();
        var r = job.AddRecord(RequestId, ExportAction.Create);
        job.RecordFailure(r.Id, "E1");
        job.RecordFailure(r.Id, "E2");
        job.RecordFailure(r.Id, "E3");

        r.AdminReset();

        r.RetryCount.Should().Be(0);
        r.Status.Should().Be(ExportRecordStatus.Pending);
        r.ErrorMessage.Should().BeNull();
    }
}
