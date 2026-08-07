using FluentAssertions;
using IdentitySync.Domain.Application;
using IdentitySync.Domain.Graph;
using IdentitySync.Domain.SyncJobs;
using Xunit;

namespace IdentitySync.Domain.Tests.Application;

// T011: UpsertEmployeeFromAdHandler — creation, deactivation, dept change, manager pass
public class UpsertEmployeeFromAdHandlerTests
{
    // ─── In-memory fakes ─────────────────────────────────────────────────────

    private sealed class FakeGraphClient : IGraphApiClient
    {
        private readonly IReadOnlyList<AdUserDto> _users;
        private readonly Dictionary<string, IReadOnlyList<string>> _groups;

        public FakeGraphClient(
            IReadOnlyList<AdUserDto> users,
            Dictionary<string, IReadOnlyList<string>>? groups = null)
        {
            _users = users;
            _groups = groups ?? new();
        }

        public async IAsyncEnumerable<AdUserDto> GetAllUsersAsync(
            [System.Runtime.CompilerServices.EnumeratorCancellation] CancellationToken ct)
        {
            foreach (var u in _users)
                yield return u;
            await Task.CompletedTask;
        }

        public Task<IReadOnlyList<string>> GetUserGroupNamesAsync(
            string userId, CancellationToken ct) =>
            Task.FromResult(_groups.TryGetValue(userId, out var g)
                ? g : (IReadOnlyList<string>)[]);
    }

    private sealed class FakeEmployeeRepo : IEmployeeUpsertRepository
    {
        public Dictionary<string, UpsertEmployeeCommand> Upserted { get; } = new();
        public HashSet<string> Deactivated { get; } = new();
        public Dictionary<string, string> ManagerAssignments { get; } = new();
        private readonly HashSet<string> _existing;

        public FakeEmployeeRepo(params string[] existingIds) => _existing = [.. existingIds];

        public Task<bool> UpsertAsync(UpsertEmployeeCommand cmd, CancellationToken ct)
        {
            Upserted[cmd.ExternalAdId] = cmd;
            var created = !_existing.Contains(cmd.ExternalAdId);
            return Task.FromResult(created);
        }

        public Task<bool> DeactivateAsync(string externalAdId, CancellationToken ct)
        {
            var wasActive = !Deactivated.Contains(externalAdId);
            Deactivated.Add(externalAdId);
            return Task.FromResult(wasActive);
        }

        public Task<IReadOnlyList<string>> GetAllExternalAdIdsAsync(CancellationToken ct) =>
            Task.FromResult<IReadOnlyList<string>>(_existing.ToList());

        public Task SetManagerAsync(string empId, string mgId, CancellationToken ct)
        {
            ManagerAssignments[empId] = mgId;
            return Task.CompletedTask;
        }
    }

    // ─── Tests ───────────────────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Execute_NewEmployee_GetsCreatedAndCountedCorrectly()
    {
        var users = new[]
        {
            new AdUserDto("ad-001", "Ana", "García", "Ana García",
                "ana@company.com", "Engineering", null, true, null)
        };
        var repo = new FakeEmployeeRepo(); // no existing users
        var handler = new UpsertEmployeeFromAdHandler(repo, new FakeGraphClient(users));
        var job = SyncJob.Start(SyncJobType.Scheduled);

        var (created, updated, _, _) = await handler.ExecuteAsync(job, default);

        created.Should().Be(1);
        updated.Should().Be(0);
        repo.Upserted.Should().ContainKey("ad-001");
        repo.Upserted["ad-001"].Email.Should().Be("ana@company.com");
        repo.Upserted["ad-001"].Role.Should().Be(EmployeeRole.Employee);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Execute_ExistingEmployee_GetsUpdatedNotCreated()
    {
        var users = new[]
        {
            new AdUserDto("ad-001", "Ana", "García", "Ana García",
                "ana@company.com", "Marketing", null, true, null)
        };
        var repo = new FakeEmployeeRepo("ad-001"); // already exists
        var handler = new UpsertEmployeeFromAdHandler(repo, new FakeGraphClient(users));
        var job = SyncJob.Start(SyncJobType.Scheduled);

        var (created, updated, _, _) = await handler.ExecuteAsync(job, default);

        created.Should().Be(0);
        repo.Upserted["ad-001"].Department.Should().Be("Marketing");
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Execute_DisabledUser_IsDeactivated_NotUpserted()
    {
        // BR-056: accountEnabled=false → IsActive=false (soft-delete only)
        var users = new[]
        {
            new AdUserDto("ad-001", "Former", "Employee", "Former Employee",
                "former@company.com", "HR", null, AccountEnabled: false, null)
        };
        var repo = new FakeEmployeeRepo("ad-001");
        var handler = new UpsertEmployeeFromAdHandler(repo, new FakeGraphClient(users));
        var job = SyncJob.Start(SyncJobType.Scheduled);

        await handler.ExecuteAsync(job, default);

        repo.Deactivated.Should().Contain("ad-001");
        repo.Upserted.Should().NotContainKey("ad-001"); // NOT hard-deleted, NOT upserted
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Execute_WithManagerId_ResolvesInSecondPass()
    {
        var users = new[]
        {
            new AdUserDto("ad-emp", "Ana", "García", null,
                "ana@co.com", "Eng", null, true, "ad-mgr"),
            new AdUserDto("ad-mgr", "Carlos", "Ruiz", null,
                "carlos@co.com", "Eng", null, true, null)
        };
        var repo = new FakeEmployeeRepo();
        var handler = new UpsertEmployeeFromAdHandler(repo, new FakeGraphClient(users));
        var job = SyncJob.Start(SyncJobType.Scheduled);

        await handler.ExecuteAsync(job, default);

        repo.ManagerAssignments.Should().ContainKey("ad-emp");
        repo.ManagerAssignments["ad-emp"].Should().Be("ad-mgr");
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Execute_WithPMGroupMembership_AssignsProjectManagerRole()
    {
        var users = new[]
        {
            new AdUserDto("ad-pm", "Carlos", "Ruiz", null,
                "carlos@co.com", "Eng", null, true, null)
        };
        var groups = new Dictionary<string, IReadOnlyList<string>>
        {
            ["ad-pm"] = ["VacationSystem-ProjectManagers"]
        };
        var repo = new FakeEmployeeRepo();
        var handler = new UpsertEmployeeFromAdHandler(
            repo, new FakeGraphClient(users, groups));
        var job = SyncJob.Start(SyncJobType.Scheduled);

        await handler.ExecuteAsync(job, default);

        repo.Upserted["ad-pm"].Role.Should().Be(EmployeeRole.ProjectManager);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Execute_MultipleUsers_ProcessesAllConcurrently()
    {
        var users = Enumerable.Range(1, 30)
            .Select(i => new AdUserDto($"ad-{i:D3}", "First", "Last", null,
                $"user{i}@co.com", "Eng", null, true, null))
            .ToList();

        var repo = new FakeEmployeeRepo();
        var handler = new UpsertEmployeeFromAdHandler(repo, new FakeGraphClient(users));
        var job = SyncJob.Start(SyncJobType.Scheduled);

        var (created, _, _, errs) = await handler.ExecuteAsync(job, default);

        created.Should().Be(30);
        errs.Should().Be(0);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Execute_WhenUpsertThrows_RecordsErrorOnJob()
    {
        var users = new[]
        {
            new AdUserDto("ad-err", "Bad", "User", null, "bad@co.com", "Eng", null, true, null)
        };

        // Repo that throws on upsert
        var repo = new ThrowingRepo();
        var handler = new UpsertEmployeeFromAdHandler(repo, new FakeGraphClient(users));
        var job = SyncJob.Start(SyncJobType.Scheduled);

        await handler.ExecuteAsync(job, default);

        job.ErrorCount.Should().BeGreaterThan(0);
        job.Errors.Should().Contain(e => e.EmployeeExternalId == "ad-err");
    }

    private sealed class ThrowingRepo : IEmployeeUpsertRepository
    {
        public Task<bool> UpsertAsync(UpsertEmployeeCommand _, CancellationToken __) =>
            throw new InvalidOperationException("DB unavailable");
        public Task<bool> DeactivateAsync(string _, CancellationToken __) =>
            Task.FromResult(false);
        public Task<IReadOnlyList<string>> GetAllExternalAdIdsAsync(CancellationToken _) =>
            Task.FromResult<IReadOnlyList<string>>([]);
        public Task SetManagerAsync(string _, string __, CancellationToken ___) =>
            Task.CompletedTask;
    }
}
