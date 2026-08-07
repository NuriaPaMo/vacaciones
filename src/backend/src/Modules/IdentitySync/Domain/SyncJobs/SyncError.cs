using VacationManagement.Domain.Common;

namespace IdentitySync.Domain.SyncJobs;

// INV-010 (SyncError): append-only; never modified or deleted
public sealed class SyncError
{
    public Guid Id { get; private set; }
    public Guid JobId { get; private set; }
    public string EmployeeExternalId { get; private set; }
    public string ErrorMessage { get; private set; }
    public int RetryCount { get; private set; }
    public bool IsResolved { get; private set; }
    public DateTime CreatedAt { get; private set; }

    private SyncError() { EmployeeExternalId = string.Empty; ErrorMessage = string.Empty; }

    internal static SyncError Create(
        Guid jobId, string employeeExternalId, string errorMessage, int retryCount) =>
        new()
        {
            Id = Guid.NewGuid(),
            JobId = jobId,
            EmployeeExternalId = employeeExternalId,
            ErrorMessage = errorMessage,
            RetryCount = retryCount,
            IsResolved = false,
            CreatedAt = DateTime.UtcNow
        };

    internal void MarkResolved() => IsResolved = true;
}
