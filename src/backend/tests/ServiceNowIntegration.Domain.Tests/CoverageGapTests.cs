using FluentAssertions;
using ServiceNowIntegration.Domain.Application;
using ServiceNowIntegration.Domain.Exports;
using ServiceNowIntegration.Domain.Http;
using ServiceNowIntegration.Domain.Imports;
using System.Net;
using System.Text.Json;
using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;
using Xunit;

namespace ServiceNowIntegration.Domain.Tests;

// Branch-gap coverage: ExportJob.Fail, Update action, ExportRecordPermanentlyFailed event, ImportJob edge cases
public class CoverageGapTests
{
    private static string SysIdResponse(string id) =>
        JsonSerializer.Serialize(new { result = new { sys_id = id } });

    // ─── ExportJob.Fail ───────────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void ExportJob_Fail_SetsFailedStatus()
    {
        var job = ExportJob.Start();
        job.Fail("Unexpected exception");

        job.Status.Should().Be(ExportJobStatus.Failed);
        job.IsTerminal().Should().BeTrue();
        job.ErrorCount.Should().Be(1);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void ExportJob_Fail_WhenTerminal_ThrowsDomainException()
    {
        var job = ExportJob.Start();
        job.Complete();

        var act = () => job.Fail("Late failure");
        act.Should().Throw<DomainException>();
    }

    // ─── Update action counting ───────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void ExportJob_RecordSuccess_MultipleActions_CountsCorrectly()
    {
        var job = ExportJob.Start();
        var r1 = job.AddRecord(VacationRequestId.New(), ExportAction.Create);
        var r2 = job.AddRecord(VacationRequestId.New(), ExportAction.Update);
        var r3 = job.AddRecord(VacationRequestId.New(), ExportAction.Delete);

        job.RecordSuccess(r1.Id, "SYS1");
        job.RecordSuccess(r2.Id, "SYS2");
        job.RecordSuccess(r3.Id, "SYS3");

        job.TotalExported.Should().Be(1);
        job.TotalUpdated.Should().Be(1);
        job.TotalDeleted.Should().Be(1);
    }

    // ─── ExportRecord paths ───────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void ExportRecord_SucceededState_HasCorrectFields()
    {
        var job = ExportJob.Start();
        var r = job.AddRecord(VacationRequestId.New(), ExportAction.Create);
        job.RecordSuccess(r.Id, "SYSABC");

        r.ServiceNowRecordId.Should().Be("SYSABC");
        r.ExportedAt.Should().NotBeNull();
        r.ErrorMessage.Should().BeNull();
        r.RetryCount.Should().Be(0);
    }

    // ─── ImportJob RecordError multiple times ─────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void ImportJob_MultipleRecordError_CumulatesCount()
    {
        var job = ImportJob.Start();
        job.RecordError();
        job.RecordError();
        job.RecordError();

        job.ErrorCount.Should().Be(3);
    }

    // ─── TriggerNightlyExportHandler — Update path ────────────────────────────

    private sealed class FakeExportJobRepo : IExportJobRepository
    {
        public Task<ExportJob?> GetRunningJobAsync(CancellationToken ct) =>
            Task.FromResult<ExportJob?>(null);
        public Task SaveAsync(ExportJob job, CancellationToken ct) => Task.CompletedTask;
    }

    private sealed class AlwaysSucceedingClient : IServiceNowHttpClient
    {
        private int _callCount;
        public Task<string> PostAsync(string _, object __, CancellationToken ___) =>
            Task.FromResult($"SYS{++_callCount:D3}");
        public Task UpdateAsync(string _, string __, object ___, CancellationToken ____) =>
            Task.CompletedTask;
        public Task DeleteAsync(string _, string __, CancellationToken ___) =>
            Task.CompletedTask;
        public Task<(IReadOnlyList<Dictionary<string, string>>, string?)> GetPageAsync(
            string _, string? __, CancellationToken ___) =>
            throw new NotImplementedException();
    }

    private sealed class FakePendingQuery : IPendingVacationExportQuery
    {
        private readonly (VacationRequestId, ExportAction, string?)[] _items;
        public FakePendingQuery(params (VacationRequestId, ExportAction, string?)[] items) =>
            _items = items;
        public Task<IReadOnlyList<(VacationRequestId, ExportAction, string?)>> GetPendingAsync(
            CancellationToken ct) => Task.FromResult<IReadOnlyList<(VacationRequestId, ExportAction, string?)>>(_items);
    }

    private sealed class FakeDetailsQuery : IVacationExportDetailsQuery
    {
        public Task<VacationExportDto> GetDetailsAsync(VacationRequestId id, CancellationToken ct) =>
            Task.FromResult(new VacationExportDto("Ana", "ad-1", "2026-08-10", "2026-08-14", 5, "Approved", "Eng", id.Value.ToString()));
    }

    private sealed class FakeStateUpdater : IVacationRequestExportStateUpdater
    {
        public Task MarkExportedAsync(VacationRequestId id, string sysId, CancellationToken ct) =>
            Task.CompletedTask;
    }

    private sealed class FakePublisher : IDomainEventPublisher
    {
        public List<IDomainEvent> Published { get; } = [];
        public Task PublishAsync(IDomainEvent e, CancellationToken _) { Published.Add(e); return Task.CompletedTask; }
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Handler_UpdateRecord_CountsAsUpdated()
    {
        var reqId = VacationRequestId.New();
        var publisher = new FakePublisher();
        var handler = new TriggerNightlyExportHandler(
            new FakePendingQuery((reqId, ExportAction.Update, "SYS_OLD")),
            new FakeDetailsQuery(), new FakeStateUpdater(),
            new AlwaysSucceedingClient(), new FakeExportJobRepo(), publisher);

        var job = await handler.ExecuteAsync();

        job.TotalUpdated.Should().Be(1);
        job.Status.Should().Be(ExportJobStatus.Completed);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Handler_ExceedsErrorThreshold_PublishedInEvent()
    {
        // Create 20 records, 2 fail (10% > 5% threshold)
        var pending = Enumerable.Range(0, 20)
            .Select(i => (VacationRequestId.New(), ExportAction.Create, (string?)null))
            .ToArray();

        // Client fails for 2 specific requests, succeeds for rest
        var callIdx = 0;
        var failAt = new HashSet<int> { 0, 1 };

        var errClient = new ConditionalFailClient(failAt);
        var publisher = new FakePublisher();

        var handler = new TriggerNightlyExportHandler(
            new FakePendingQuery(pending),
            new FakeDetailsQuery(), new FakeStateUpdater(),
            errClient, new FakeExportJobRepo(), publisher);

        await handler.ExecuteAsync();

        var ev = publisher.Published.OfType<ExportJobCompleted>().Single();
        ev.ErrorCount.Should().BeGreaterThan(0);
    }

    private sealed class ConditionalFailClient(HashSet<int> failAtIndices) : IServiceNowHttpClient
    {
        private int _idx;
        public Task<string> PostAsync(string _, object __, CancellationToken ___) =>
            failAtIndices.Contains(_idx++)
                ? throw new HttpRequestException("Simulated failure")
                : Task.FromResult($"SYS{_idx:D3}");
        public Task UpdateAsync(string _, string __, object ___, CancellationToken ____) => Task.CompletedTask;
        public Task DeleteAsync(string _, string __, CancellationToken ___) => Task.CompletedTask;
        public Task<(IReadOnlyList<Dictionary<string, string>>, string?)> GetPageAsync(
            string _, string? __, CancellationToken ___) => throw new NotImplementedException();
    }
}
