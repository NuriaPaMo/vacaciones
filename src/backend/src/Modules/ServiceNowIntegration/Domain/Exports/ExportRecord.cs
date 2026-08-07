using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;

namespace ServiceNowIntegration.Domain.Exports;

// Child entity — one per vacation request in a batch
// INV-402: delta sync — only export new or changed records (BR-072)
public sealed class ExportRecord
{
    private const int MaxRetries = 3;

    public Guid Id { get; private set; }
    public Guid JobId { get; private set; }
    public VacationRequestId RequestId { get; private set; }
    public ExportAction Action { get; private set; }
    public ExportRecordStatus Status { get; private set; }
    public string? ServiceNowRecordId { get; private set; }
    public DateTime? ExportedAt { get; private set; }
    public string? ErrorMessage { get; private set; }
    public int RetryCount { get; private set; }

    private ExportRecord() { } // EF Core

    internal static ExportRecord Create(
        Guid jobId, VacationRequestId requestId, ExportAction action) =>
        new()
        {
            Id = Guid.NewGuid(),
            JobId = jobId,
            RequestId = requestId,
            Action = action,
            Status = ExportRecordStatus.Pending,
            RetryCount = 0
        };

    internal void MarkSucceeded(string serviceNowRecordId)
    {
        ServiceNowRecordId = serviceNowRecordId;
        ExportedAt = DateTime.UtcNow;
        ErrorMessage = null;
        Status = ExportRecordStatus.Succeeded;
    }

    internal void MarkFailed(string errorMessage)
    {
        ErrorMessage = errorMessage;
        RetryCount++;
        Status = RetryCount >= MaxRetries
            ? ExportRecordStatus.MaxRetriesExceeded
            : ExportRecordStatus.Failed;
    }

    // Returns false when max retries exhausted — caller should stop retrying
    public bool Retry()
    {
        if (RetryCount >= MaxRetries)
            return false;
        Status = ExportRecordStatus.Pending;
        return true;
    }

    // Admin manual retry resets the counter (BR-082)
    public void AdminReset()
    {
        RetryCount = 0;
        Status = ExportRecordStatus.Pending;
        ErrorMessage = null;
    }
}
