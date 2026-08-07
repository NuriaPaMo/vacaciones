using CapacityManagement.Domain.Capacity;
using CapacityManagement.Domain.Capacity.Events;
using CapacityManagement.Domain.Capacity.ValueObjects;
using FluentAssertions;
using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;
using Xunit;

namespace CapacityManagement.Domain.Tests.Capacity;

// T012: RecomputeCapacitySnapshotsHandler — in-memory port implementations (no Testcontainers)
// Integration tests with real DB (Testcontainers) are deferred to Bolt 3B when EF Core is wired up.
public class RecomputeHandlerTests
{
    private static readonly EmployeeId SystemUser = EmployeeId.New();

    // ─── In-memory fakes ─────────────────────────────────────────────────────

    private sealed class FakeSnapshotRepo : ICapacitySnapshotRepository
    {
        private readonly Dictionary<string, CapacitySnapshot> _store = new();

        public Task<CapacitySnapshot?> FindAsync(
            DateOnly date, OrganizationLevel level, Guid entityId, CancellationToken ct)
        {
            var key = $"{date}|{level}|{entityId}";
            return Task.FromResult(_store.TryGetValue(key, out var s) ? s : null);
        }

        public Task UpsertAsync(CapacitySnapshot snapshot, CancellationToken ct)
        {
            _store[$"{snapshot.Date}|{snapshot.Level}|{snapshot.LevelEntityId}"] = snapshot;
            return Task.CompletedTask;
        }

        public IReadOnlyDictionary<string, CapacitySnapshot> All => _store;
    }

    private sealed class FakeThresholdRepo : IThresholdConfigRepository
    {
        private readonly ThresholdConfig _global;
        private ThresholdConfig? _dept;

        public FakeThresholdRepo(ThresholdConfig global) => _global = global;

        public void SetDept(ThresholdConfig dept) => _dept = dept;

        public Task<ThresholdConfig> GetEffectiveAsync(Guid? departmentId, CancellationToken ct)
        {
            var result = _dept?.IsApplicableTo(departmentId) == true ? _dept : _global;
            return Task.FromResult(result);
        }

        public Task<ThresholdConfig?> FindGlobalAsync(CancellationToken ct) =>
            Task.FromResult<ThresholdConfig?>(_global);

        public Task UpsertAsync(ThresholdConfig config, CancellationToken ct) =>
            Task.CompletedTask;
    }

    private sealed class FakeHeadcountQuery : IEmployeeHeadcountQuery
    {
        private readonly Func<DateOnly, (int, int, int)> _factory;
        public FakeHeadcountQuery(Func<DateOnly, (int, int, int)> factory) => _factory = factory;

        public Task<(int Total, int OnVacation, int Pending)> GetCountsAsync(
            Guid _, OrganizationLevel __, DateOnly date, CancellationToken ___)
            => Task.FromResult(_factory(date));
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

    // ─── Tests ───────────────────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Handle_3DayRange_CreatesThreeSnapshots()
    {
        var entityId = Guid.NewGuid();
        var repo = new FakeSnapshotRepo();
        var threshold = new FakeThresholdRepo(ThresholdConfig.Default(SystemUser));
        var headcount = new FakeHeadcountQuery(_ => (10, 3, 1)); // 40% all days
        var publisher = new FakePublisher();
        var handler = new RecomputeCapacitySnapshotsHandler(repo, threshold, headcount, publisher);

        await handler.HandleAsync(new RecomputeCapacitySnapshotsCommand(
            entityId, OrganizationLevel.Department,
            new DateOnly(2026, 8, 10), new DateOnly(2026, 8, 12)));

        repo.All.Should().HaveCount(3);
        repo.All.Values.Should().OnlyContain(s => s.CapacityPercentage == 40m);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Handle_WhenThresholdCrossedCritical_PublishesCriticalEvent()
    {
        var entityId = Guid.NewGuid();
        var repo = new FakeSnapshotRepo();
        var threshold = new FakeThresholdRepo(ThresholdConfig.Default(SystemUser));
        var headcount = new FakeHeadcountQuery(_ => (10, 8, 0)); // 80% → critical
        var publisher = new FakePublisher();
        var handler = new RecomputeCapacitySnapshotsHandler(repo, threshold, headcount, publisher);

        await handler.HandleAsync(new RecomputeCapacitySnapshotsCommand(
            entityId, OrganizationLevel.Department,
            new DateOnly(2026, 8, 10), new DateOnly(2026, 8, 10)));

        publisher.Published.Should().Contain(e => e is CapacityCriticalThresholdCrossed);
        publisher.Published.Should().NotContain(e => e is CapacityWarningThresholdCrossed);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Handle_WhenThresholdCrossedWarningOnly_PublishesWarningEvent()
    {
        var entityId = Guid.NewGuid();
        var repo = new FakeSnapshotRepo();
        var threshold = new FakeThresholdRepo(ThresholdConfig.Default(SystemUser));
        var headcount = new FakeHeadcountQuery(_ => (10, 7, 0)); // 70% → warning (65≤pct≤70)
        var publisher = new FakePublisher();
        var handler = new RecomputeCapacitySnapshotsHandler(repo, threshold, headcount, publisher);

        await handler.HandleAsync(new RecomputeCapacitySnapshotsCommand(
            entityId, OrganizationLevel.Department,
            new DateOnly(2026, 8, 10), new DateOnly(2026, 8, 10)));

        publisher.Published.Should().Contain(e => e is CapacityWarningThresholdCrossed);
        publisher.Published.Should().NotContain(e => e is CapacityCriticalThresholdCrossed);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Handle_NoCrossing_OnlyPublishesInvalidationEvent()
    {
        var entityId = Guid.NewGuid();
        var repo = new FakeSnapshotRepo();
        var threshold = new FakeThresholdRepo(ThresholdConfig.Default(SystemUser));
        var headcount = new FakeHeadcountQuery(_ => (10, 2, 0)); // 20% → green
        var publisher = new FakePublisher();
        var handler = new RecomputeCapacitySnapshotsHandler(repo, threshold, headcount, publisher);

        await handler.HandleAsync(new RecomputeCapacitySnapshotsCommand(
            entityId, OrganizationLevel.Department,
            new DateOnly(2026, 8, 10), new DateOnly(2026, 8, 10)));

        publisher.Published.Should().NotContain(e => e is CapacityCriticalThresholdCrossed);
        publisher.Published.Should().NotContain(e => e is CapacityWarningThresholdCrossed);
        publisher.Published.Should().ContainSingle(e => e is CapacitySnapshotInvalidated);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Handle_WhenTotalEmployeesIsZero_SkipsDay()
    {
        var entityId = Guid.NewGuid();
        var repo = new FakeSnapshotRepo();
        var threshold = new FakeThresholdRepo(ThresholdConfig.Default(SystemUser));
        var headcount = new FakeHeadcountQuery(_ => (0, 0, 0)); // empty team
        var publisher = new FakePublisher();
        var handler = new RecomputeCapacitySnapshotsHandler(repo, threshold, headcount, publisher);

        await handler.HandleAsync(new RecomputeCapacitySnapshotsCommand(
            entityId, OrganizationLevel.Department,
            new DateOnly(2026, 8, 10), new DateOnly(2026, 8, 12)));

        // INV-204: all three days skipped; only the invalidation event published
        repo.All.Should().BeEmpty();
        publisher.Published.Should().ContainSingle(e => e is CapacitySnapshotInvalidated);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Handle_Recompute_ExistingSnapshot_DoesNotFireEventAgain()
    {
        var entityId = Guid.NewGuid();
        var repo = new FakeSnapshotRepo();
        var threshold = new FakeThresholdRepo(ThresholdConfig.Default(SystemUser));
        // First run: 80% → critical; second run: same values → no re-firing
        var headcount = new FakeHeadcountQuery(_ => (10, 8, 0));
        var publisher = new FakePublisher();
        var handler = new RecomputeCapacitySnapshotsHandler(repo, threshold, headcount, publisher);

        var cmd = new RecomputeCapacitySnapshotsCommand(
            entityId, OrganizationLevel.Department,
            new DateOnly(2026, 8, 10), new DateOnly(2026, 8, 10));

        await handler.HandleAsync(cmd);
        var firstRunEvents = publisher.Published.Count;

        publisher.Published.Clear();
        await handler.HandleAsync(cmd); // re-run same range

        // Second run: snapshot already critical → no duplicate critical event (BR-098 dedup)
        publisher.Published.Should().NotContain(e => e is CapacityCriticalThresholdCrossed);
        publisher.Published.Should().ContainSingle(e => e is CapacitySnapshotInvalidated);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Handle_AlwaysPublishesInvalidationEvent()
    {
        var entityId = Guid.NewGuid();
        var repo = new FakeSnapshotRepo();
        var threshold = new FakeThresholdRepo(ThresholdConfig.Default(SystemUser));
        var headcount = new FakeHeadcountQuery(_ => (10, 5, 0));
        var publisher = new FakePublisher();
        var handler = new RecomputeCapacitySnapshotsHandler(repo, threshold, headcount, publisher);

        await handler.HandleAsync(new RecomputeCapacitySnapshotsCommand(
            entityId, OrganizationLevel.Department,
            new DateOnly(2026, 8, 10), new DateOnly(2026, 8, 14)));

        publisher.Published
            .OfType<CapacitySnapshotInvalidated>()
            .Should().ContainSingle()
            .Which.Should().Match<CapacitySnapshotInvalidated>(e =>
                e.FromDate == new DateOnly(2026, 8, 10) &&
                e.ToDate == new DateOnly(2026, 8, 14));
    }
}
