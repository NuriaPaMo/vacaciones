using IdentitySync.Domain.Graph;
using IdentitySync.Domain.SyncJobs;
using VacationManagement.Domain.Common;

namespace IdentitySync.Domain.Application;

// Port interfaces — implemented in Infrastructure (EF Core repositories)
public interface ISyncJobRepository
{
    Task<SyncJob?> GetRunningJobAsync(CancellationToken ct);
    Task SaveAsync(SyncJob job, CancellationToken ct);
    Task<SyncJob?> GetLastCompletedAsync(CancellationToken ct);
}

public interface IEmployeeUpsertRepository
{
    // Returns true if employee was created (not updated)
    Task<bool> UpsertAsync(UpsertEmployeeCommand cmd, CancellationToken ct);
    // Returns true if employee was deactivated
    Task<bool> DeactivateAsync(string externalAdId, CancellationToken ct);
    Task<IReadOnlyList<string>> GetAllExternalAdIdsAsync(CancellationToken ct);
    // Second-pass: resolve ManagerId from ExternalAdId
    Task SetManagerAsync(string employeeExternalAdId, string managerExternalAdId, CancellationToken ct);
}

public interface IDomainEventPublisher
{
    Task PublishAsync(IDomainEvent @event, CancellationToken ct);
}
