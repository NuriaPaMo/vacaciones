using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;

namespace ServiceNowIntegration.Domain.Exports;

// INV-401: only Approved requests exported
// INV-402: delta sync — IsExported=false OR cancelled+previously-exported → Delete
// INV-403: failed records do not block the rest of the batch (BR-075)
// INV-404: only one Running export job at any time
public sealed class ExportJob
{
    private readonly List<ExportRecord> _records = [];

    public Guid Id { get; private set; }
    public ExportJobStatus Status { get; private set; }
    public DateTime StartedAt { get; private set; }
    public DateTime? CompletedAt { get; private set; }
    public int TotalExported { get; private set; }
    public int TotalUpdated { get; private set; }
    public int TotalDeleted { get; private set; }
    public int ErrorCount { get; private set; }
    public IReadOnlyList<ExportRecord> Records => _records.AsReadOnly();

    private ExportJob() { } // EF Core

    public static ExportJob Start() =>
        new()
        {
            Id = Guid.NewGuid(),
            Status = ExportJobStatus.Running,
            StartedAt = DateTime.UtcNow
        };

    public ExportRecord AddRecord(VacationRequestId requestId, ExportAction action)
    {
        EnsureRunning();
        var record = ExportRecord.Create(Id, requestId, action);
        _records.Add(record);
        return record;
    }

    public void RecordSuccess(Guid exportRecordId, string serviceNowRecordId)
    {
        EnsureRunning();
        var record = FindRecord(exportRecordId);
        record.MarkSucceeded(serviceNowRecordId);

        switch (record.Action)
        {
            case ExportAction.Create: TotalExported++; break;
            case ExportAction.Update: TotalUpdated++; break;
            case ExportAction.Delete: TotalDeleted++; break;
        }
    }

    public void RecordFailure(Guid exportRecordId, string errorMessage)
    {
        EnsureRunning();
        FindRecord(exportRecordId).MarkFailed(errorMessage);
        ErrorCount++;
    }

    public void Complete()
    {
        EnsureRunning();
        Status = ErrorCount > 0 ? ExportJobStatus.CompletedWithErrors : ExportJobStatus.Completed;
        CompletedAt = DateTime.UtcNow;
    }

    public void Fail(string reason)
    {
        EnsureRunning();
        _records.Add(ExportRecord.Create(
            Id, VacationRequestId.From(Guid.Empty), ExportAction.Create));
        _records[^1].MarkFailed(reason);
        ErrorCount++;
        Status = ExportJobStatus.Failed;
        CompletedAt = DateTime.UtcNow;
    }

    public bool IsTerminal() =>
        Status is ExportJobStatus.Completed or ExportJobStatus.CompletedWithErrors or ExportJobStatus.Failed;

    // BR-081: alert if error rate exceeds 5%
    public bool ExceedsErrorThreshold() =>
        _records.Count > 0 && (double)ErrorCount / _records.Count > 0.05;

    private ExportRecord FindRecord(Guid id) =>
        _records.Find(r => r.Id == id)
        ?? throw new DomainException($"ExportRecord {id} not found in job {Id}.");

    private void EnsureRunning()
    {
        if (Status != ExportJobStatus.Running)
            throw new DomainException($"ExportJob is already in terminal state {Status}.");
    }
}
