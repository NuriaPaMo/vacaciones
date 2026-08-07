namespace ServiceNowIntegration.Domain.Imports;

// Tracks nightly vacation balance import from ServiceNow (runs at 6AM after export)
public sealed class ImportJob
{
    public Guid Id { get; private set; }
    public ImportJobStatus Status { get; private set; }
    public DateTime StartedAt { get; private set; }
    public DateTime? CompletedAt { get; private set; }
    public int TotalProcessed { get; private set; }
    public int Updated { get; private set; }
    public int ErrorCount { get; private set; }

    private ImportJob() { } // EF Core

    public static ImportJob Start() =>
        new() { Id = Guid.NewGuid(), Status = ImportJobStatus.Running, StartedAt = DateTime.UtcNow };

    // BR-078: circuit breaker open → skip import; stale balance used
    public static ImportJob Skipped() =>
        new()
        {
            Id = Guid.NewGuid(),
            Status = ImportJobStatus.Skipped,
            StartedAt = DateTime.UtcNow,
            CompletedAt = DateTime.UtcNow
        };

    public void RecordError()
    {
        EnsureRunning();
        ErrorCount++;
    }

    public void Complete(int totalProcessed, int updated)
    {
        EnsureRunning();
        TotalProcessed = totalProcessed;
        Updated = updated;
        Status = ErrorCount > 0 ? ImportJobStatus.CompletedWithErrors : ImportJobStatus.Completed;
        CompletedAt = DateTime.UtcNow;
    }

    public void Fail()
    {
        EnsureRunning();
        Status = ImportJobStatus.Failed;
        CompletedAt = DateTime.UtcNow;
    }

    public bool IsTerminal() =>
        Status is not ImportJobStatus.Running;

    private void EnsureRunning()
    {
        if (Status != ImportJobStatus.Running)
            throw new VacationManagement.Domain.Common.DomainException(
                $"ImportJob is already in terminal state {Status}.");
    }
}
