using IdentitySync.Domain.Graph;
using IdentitySync.Domain.SyncJobs;
using VacationManagement.Domain.Common;

namespace IdentitySync.Domain.Application;

// Domain event — published after each sync job completes
public sealed record SyncJobCompleted(
    Guid EventId,
    DateTime OccurredOn,
    Guid JobId,
    SyncJobType JobType,
    SyncJobStatus Status,
    int TotalProcessed,
    int Created,
    int Updated,
    int Deactivated,
    int ErrorCount,
    bool ExceedsErrorThreshold) : IDomainEvent;
