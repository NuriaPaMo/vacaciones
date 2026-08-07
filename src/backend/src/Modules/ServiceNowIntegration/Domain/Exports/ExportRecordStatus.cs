namespace ServiceNowIntegration.Domain.Exports;

public enum ExportRecordStatus
{
    Pending,
    Succeeded,
    Failed,
    MaxRetriesExceeded
}
