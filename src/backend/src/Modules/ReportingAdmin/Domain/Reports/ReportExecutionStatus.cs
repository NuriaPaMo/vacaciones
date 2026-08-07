namespace ReportingAdmin.Domain.Reports;

public enum ReportExecutionStatus
{
    Queued,
    Generating,
    Completed,
    Failed
}
