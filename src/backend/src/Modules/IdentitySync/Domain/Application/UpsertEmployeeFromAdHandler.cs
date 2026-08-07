using IdentitySync.Domain.Graph;
using IdentitySync.Domain.SyncJobs;

namespace IdentitySync.Domain.Application;

// Orchestrates the full AD sync run:
// Pass 1 — upsert all users, collect managers for pass 2
// Pass 2 — resolve manager relationships by ExternalAdId
// BR-056: accountEnabled=false → IsActive=false (soft-delete only)
// BR-058: role from AD group membership
// INV-303: uses SemaphoreSlim(10) for bounded parallelism
public sealed class UpsertEmployeeFromAdHandler
{
    private readonly IEmployeeUpsertRepository _employees;
    private readonly IGraphApiClient _graph;

    public UpsertEmployeeFromAdHandler(
        IEmployeeUpsertRepository employees,
        IGraphApiClient graph)
    {
        _employees = employees;
        _graph = graph;
    }

    public async Task<(int Created, int Updated, int Deactivated, int Errors)> ExecuteAsync(
        SyncJob job,
        CancellationToken ct)
    {
        int created = 0, updated = 0, errors = 0;

        // Pass 1 — upsert users + collect manager mappings
        var managerMap = new Dictionary<string, string>(); // employeeAdId → managerAdId
        var sem = new SemaphoreSlim(10);
        var tasks = new List<Task>();

        await foreach (var user in _graph.GetAllUsersAsync(ct))
        {
            var captured = user;
            tasks.Add(Task.Run(async () =>
            {
                await sem.WaitAsync(ct);
                try
                {
                    var groups = await _graph.GetUserGroupNamesAsync(captured.Id, ct);
                    var cmd = AdUserMapper.MapToCommand(captured, groups);

                    if (!captured.AccountEnabled)
                    {
                        var deactivated = await _employees.DeactivateAsync(captured.Id, ct);
                        if (deactivated) Interlocked.Increment(ref updated);
                    }
                    else
                    {
                        var wasCreated = await _employees.UpsertAsync(cmd, ct);
                        if (wasCreated) Interlocked.Increment(ref created);
                        else Interlocked.Increment(ref updated);
                    }

                    if (captured.ManagerId is not null)
                        lock (managerMap) { managerMap[captured.Id] = captured.ManagerId; }
                }
                catch (Exception ex)
                {
                    job.RecordError(captured.Id, ex.Message, retryCount: 0);
                    Interlocked.Increment(ref errors);
                }
                finally
                {
                    sem.Release();
                }
            }, ct));
        }

        await Task.WhenAll(tasks);

        // Pass 2 — resolve manager relationships
        foreach (var (empId, mgId) in managerMap)
        {
            try
            {
                await _employees.SetManagerAsync(empId, mgId, ct);
            }
            catch (Exception ex)
            {
                job.RecordError(empId, $"Manager resolution failed: {ex.Message}", retryCount: 0);
                errors++;
            }
        }

        int deactivated = 0; // counted inline above via updated counter
        return (created, updated, deactivated, errors);
    }
}
