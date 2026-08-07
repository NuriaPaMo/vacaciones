using VacationManagement.Domain.Common;

namespace IdentitySync.Domain.SyncJobs;

// INV-301: only one Running job at any time (enforced by Redis lock in handler)
// INV-302: max 1 manual sync per hour (enforced by handler rate-limit check)
// INV-303: status transitions only forward (Running → terminal states)
// INV-304: CompletedAt must be set when status is terminal
public sealed class SyncJob
{
    private readonly List<SyncError> _errors = [];

    public Guid Id { get; private set; }
    public SyncJobType Type { get; private set; }
    public SyncJobStatus Status { get; private set; }
    public DateTime StartedAt { get; private set; }
    public DateTime? CompletedAt { get; private set; }
    public int TotalProcessed { get; private set; }
    public int Created { get; private set; }
    public int Updated { get; private set; }
    public int Deactivated { get; private set; }
    public int ErrorCount { get; private set; }
    public string? TriggeredBy { get; private set; }
    public IReadOnlyList<SyncError> Errors => _errors.AsReadOnly();

    private SyncJob() { } // EF Core

    public static SyncJob Start(SyncJobType type, string? triggeredBy = null) =>
        new()
        {
            Id = Guid.NewGuid(),
            Type = type,
            Status = SyncJobStatus.Running,
            StartedAt = DateTime.UtcNow,
            TriggeredBy = triggeredBy
        };

    public void RecordError(string employeeExternalId, string message, int retryCount)
    {
        EnsureRunning();
        _errors.Add(SyncError.Create(Id, employeeExternalId, message, retryCount));
        ErrorCount++;
    }

    // INV-303/304: Complete transitions Running → Completed or CompletedWithErrors
    public void Complete(int totalProcessed, int created, int updated, int deactivated)
    {
        EnsureRunning();
        TotalProcessed = totalProcessed;
        Created = created;
        Updated = updated;
        Deactivated = deactivated;
        Status = ErrorCount > 0 ? SyncJobStatus.CompletedWithErrors : SyncJobStatus.Completed;
        CompletedAt = DateTime.UtcNow;
    }

    // INV-303/304: Fail transitions Running → Failed
    public void Fail(string reason)
    {
        EnsureRunning();
        _errors.Add(SyncError.Create(Id, "N/A", reason, 0));
        ErrorCount++;
        Status = SyncJobStatus.Failed;
        CompletedAt = DateTime.UtcNow;
    }

    public TimeSpan? Duration() =>
        CompletedAt.HasValue ? CompletedAt.Value - StartedAt : null;

    public bool IsTerminal() =>
        Status is SyncJobStatus.Completed
            or SyncJobStatus.CompletedWithErrors
            or SyncJobStatus.Failed;

    // BR-069: error rate > 5% triggers admin alert
    public bool ExceedsErrorThreshold() =>
        TotalProcessed > 0
        && (double)ErrorCount / TotalProcessed > 0.05;

    private void EnsureRunning()
    {
        if (Status != SyncJobStatus.Running)
            throw new DomainException($"Cannot modify SyncJob in status {Status} (INV-303).");
    }
}
