namespace IdentitySync.Domain.SyncJobs;

public enum SyncJobStatus
{
    Running,
    Completed,
    CompletedWithErrors,
    Failed
}
