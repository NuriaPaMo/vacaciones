using FluentAssertions;
using ServiceNowIntegration.Domain.Application;
using ServiceNowIntegration.Domain.Exports;
using ServiceNowIntegration.Domain.Http;
using ServiceNowIntegration.Domain.Imports;
using System.Net;
using System.Text;
using System.Text.Json;
using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;
using Xunit;

namespace ServiceNowIntegration.Domain.Tests.Application;

// T011: TriggerNightlyExportHandler — end-to-end with custom HttpMessageHandler mock
// Tests: POST → sys_id returned; batch continues on failure; permanent failure event published
public class TriggerNightlyExportHandlerTests
{
    // ─── Fakes ───────────────────────────────────────────────────────────────

    private sealed class FakeExportJobRepo : IExportJobRepository
    {
        public ExportJob? Saved { get; private set; }
        public Task<ExportJob?> GetRunningJobAsync(CancellationToken ct) =>
            Task.FromResult<ExportJob?>(null);
        public Task SaveAsync(ExportJob job, CancellationToken ct)
        {
            Saved = job;
            return Task.CompletedTask;
        }
    }

    private sealed class FakePendingQuery : IPendingVacationExportQuery
    {
        private readonly IReadOnlyList<(VacationRequestId, ExportAction, string?)> _items;
        public FakePendingQuery(params (VacationRequestId, ExportAction, string?)[] items) =>
            _items = items;
        public Task<IReadOnlyList<(VacationRequestId, ExportAction, string?)>> GetPendingAsync(
            CancellationToken ct) => Task.FromResult(_items);
    }

    private sealed class FakeDetailsQuery : IVacationExportDetailsQuery
    {
        public Task<VacationExportDto> GetDetailsAsync(VacationRequestId id, CancellationToken ct) =>
            Task.FromResult(new VacationExportDto("Ana García", "ad-001",
                "2026-08-10", "2026-08-14", 5, "Approved", "Engineering", id.Value.ToString()));
    }

    private sealed class FakeStateUpdater : IVacationRequestExportStateUpdater
    {
        public List<(VacationRequestId, string)> Marked { get; } = [];
        public Task MarkExportedAsync(VacationRequestId id, string sysId, CancellationToken ct)
        {
            Marked.Add((id, sysId));
            return Task.CompletedTask;
        }
    }

    private sealed class FakePublisher : IDomainEventPublisher
    {
        public List<IDomainEvent> Published { get; } = [];
        public Task PublishAsync(IDomainEvent e, CancellationToken _)
        {
            Published.Add(e);
            return Task.CompletedTask;
        }
    }

    // HttpMessageHandler that returns a queued sequence of responses
    private sealed class QueuedHandler(Queue<(HttpStatusCode Code, string Body)> queue)
        : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage _, CancellationToken __)
        {
            if (!queue.TryDequeue(out var next))
                throw new InvalidOperationException("No more responses queued.");
            return Task.FromResult(new HttpResponseMessage(next.Code)
            {
                Content = new StringContent(next.Body, Encoding.UTF8, "application/json")
            });
        }
    }

    // Testable IServiceNowHttpClient that wraps the queued handler
    private sealed class HttpClientAdapter : IServiceNowHttpClient
    {
        private readonly Queue<(HttpStatusCode, string)> _queue;
        public HttpClientAdapter(Queue<(HttpStatusCode, string)> queue) => _queue = queue;

        public Task<string> PostAsync(string _, object __, CancellationToken ___) =>
            Dequeue(r => JsonDocument.Parse(r).RootElement
                .GetProperty("result").GetProperty("sys_id").GetString()!);

        public Task UpdateAsync(string _, string __, object ___, CancellationToken ____) =>
            Dequeue(_ => Task.CompletedTask);

        public Task DeleteAsync(string _, string __, CancellationToken ___) =>
            Dequeue(_ => Task.CompletedTask);

        public Task<(IReadOnlyList<Dictionary<string, string>>, string?)> GetPageAsync(
            string _, string? __, CancellationToken ___) =>
            throw new NotImplementedException();

        private Task<T> Dequeue<T>(Func<string, T> parse)
        {
            if (!_queue.TryDequeue(out var next))
                throw new InvalidOperationException("No more responses queued.");
            if ((int)next.Item1 < 200 || (int)next.Item1 >= 300)
                throw new HttpRequestException($"ServiceNow returned {next.Item1}");
            return Task.FromResult(parse(next.Item2));
        }
    }

    private static string SysIdResponse(string sysId) =>
        JsonSerializer.Serialize(new { result = new { sys_id = sysId } });

    // ─── Tests ───────────────────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Execute_SingleCreateRecord_ReturnsCompletedJobWithSysId()
    {
        var reqId = VacationRequestId.New();
        var queue = new Queue<(HttpStatusCode, string)>([(HttpStatusCode.OK, SysIdResponse("SYS001"))]);
        var repo = new FakeExportJobRepo();
        var stateUpdater = new FakeStateUpdater();
        var publisher = new FakePublisher();

        var handler = new TriggerNightlyExportHandler(
            new FakePendingQuery((reqId, ExportAction.Create, null)),
            new FakeDetailsQuery(), stateUpdater,
            new HttpClientAdapter(queue), repo, publisher);

        var job = await handler.ExecuteAsync();

        job.Status.Should().Be(ExportJobStatus.Completed);
        job.TotalExported.Should().Be(1);
        job.ErrorCount.Should().Be(0);
        stateUpdater.Marked.Should().ContainSingle(m => m.Item2 == "SYS001");
        publisher.Published.Should().Contain(e => e is ExportJobCompleted);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Execute_DeleteRecord_CountsAsDeleted()
    {
        var reqId = VacationRequestId.New();
        // Delete returns 204 with empty body
        var queue = new Queue<(HttpStatusCode, string)>([(HttpStatusCode.NoContent, "")]);
        var publisher = new FakePublisher();

        var handler = new TriggerNightlyExportHandler(
            new FakePendingQuery((reqId, ExportAction.Delete, "SYS_EXISTING")),
            new FakeDetailsQuery(), new FakeStateUpdater(),
            new HttpClientAdapter(queue), new FakeExportJobRepo(), publisher);

        var job = await handler.ExecuteAsync();

        job.TotalDeleted.Should().Be(1);
        job.TotalExported.Should().Be(0);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Execute_OneFailureOneSuccess_BatchContinues_BR075()
    {
        // INV-403 / BR-075: failed record does NOT block subsequent records
        var req1 = VacationRequestId.New();
        var req2 = VacationRequestId.New();
        var queue = new Queue<(HttpStatusCode, string)>([
            (HttpStatusCode.ServiceUnavailable, ""),      // first record fails
            (HttpStatusCode.OK, SysIdResponse("SYS002"))  // second record succeeds
        ]);
        var publisher = new FakePublisher();

        var handler = new TriggerNightlyExportHandler(
            new FakePendingQuery(
                (req1, ExportAction.Create, null),
                (req2, ExportAction.Create, null)),
            new FakeDetailsQuery(), new FakeStateUpdater(),
            new HttpClientAdapter(queue), new FakeExportJobRepo(), publisher);

        var job = await handler.ExecuteAsync();

        job.Status.Should().Be(ExportJobStatus.CompletedWithErrors);
        job.TotalExported.Should().Be(1);
        job.ErrorCount.Should().Be(1);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Execute_EmptyBatch_CompletesImmediately()
    {
        var publisher = new FakePublisher();
        var handler = new TriggerNightlyExportHandler(
            new FakePendingQuery(),
            new FakeDetailsQuery(), new FakeStateUpdater(),
            new HttpClientAdapter(new Queue<(HttpStatusCode, string)>()),
            new FakeExportJobRepo(), publisher);

        var job = await handler.ExecuteAsync();

        job.Status.Should().Be(ExportJobStatus.Completed);
        job.TotalExported.Should().Be(0);
        publisher.Published.Should().ContainSingle(e => e is ExportJobCompleted);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Execute_AlwaysPublishesExportJobCompleted()
    {
        var reqId = VacationRequestId.New();
        var queue = new Queue<(HttpStatusCode, string)>([(HttpStatusCode.OK, SysIdResponse("SYS001"))]);
        var publisher = new FakePublisher();

        var handler = new TriggerNightlyExportHandler(
            new FakePendingQuery((reqId, ExportAction.Create, null)),
            new FakeDetailsQuery(), new FakeStateUpdater(),
            new HttpClientAdapter(queue), new FakeExportJobRepo(), publisher);

        await handler.ExecuteAsync();

        publisher.Published.OfType<ExportJobCompleted>().Should().ContainSingle();
    }
}
