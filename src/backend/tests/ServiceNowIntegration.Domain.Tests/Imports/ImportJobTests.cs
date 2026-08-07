using FluentAssertions;
using ServiceNowIntegration.Domain.Imports;
using VacationManagement.Domain.Common;
using Xunit;

namespace ServiceNowIntegration.Domain.Tests.Imports;

// ImportJob aggregate — Start, Skipped (BR-078), Complete, Fail, RecordError
public class ImportJobTests
{
    [Fact]
    [Trait("Category", "Unit")]
    public void Start_CreatesRunningJob()
    {
        var job = ImportJob.Start();
        job.Status.Should().Be(ImportJobStatus.Running);
        job.IsTerminal().Should().BeFalse();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Skipped_CreatesTerminalSkippedJob()
    {
        var job = ImportJob.Skipped();
        job.Status.Should().Be(ImportJobStatus.Skipped);
        job.IsTerminal().Should().BeTrue();
        job.CompletedAt.Should().NotBeNull();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Complete_NoErrors_SetsCompleted()
    {
        var job = ImportJob.Start();
        job.Complete(487, 12);

        job.Status.Should().Be(ImportJobStatus.Completed);
        job.TotalProcessed.Should().Be(487);
        job.Updated.Should().Be(12);
        job.IsTerminal().Should().BeTrue();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Complete_WithErrors_SetsCompletedWithErrors()
    {
        var job = ImportJob.Start();
        job.RecordError();
        job.Complete(100, 99);

        job.Status.Should().Be(ImportJobStatus.CompletedWithErrors);
        job.ErrorCount.Should().Be(1);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Fail_SetsFailedStatus()
    {
        var job = ImportJob.Start();
        job.Fail();
        job.Status.Should().Be(ImportJobStatus.Failed);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Complete_WhenTerminal_ThrowsDomainException()
    {
        var job = ImportJob.Start();
        job.Fail();

        var act = () => job.Complete(10, 10);
        act.Should().Throw<DomainException>();
    }
}
