using ReportingAdmin.Domain.Reports;
using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;

namespace ReportingAdmin.Domain.Reports;

public sealed class ReportExecution
{
    public Guid Id { get; private set; }
    public ReportType ReportType { get; private set; }
    public string ParametersJson { get; private set; }
    public EmployeeId GeneratedBy { get; private set; }
    public DateTime RequestedAt { get; private set; }
    public DateTime? CompletedAt { get; private set; }
    public ReportExecutionStatus Status { get; private set; }
    public string? FileUrl { get; private set; }
    public ReportFormat Format { get; private set; }
    public long? FileSizeBytes { get; private set; }

    private ReportExecution() { ParametersJson = string.Empty; }

    public static ReportExecution Create(
        ReportType type, ReportFormat format,
        string parametersJson, EmployeeId generatedBy) =>
        new()
        {
            Id = Guid.NewGuid(),
            ReportType = type,
            Format = format,
            ParametersJson = parametersJson,
            GeneratedBy = generatedBy,
            RequestedAt = DateTime.UtcNow,
            Status = ReportExecutionStatus.Queued
        };

    public void StartGenerating()
    {
        if (Status != ReportExecutionStatus.Queued)
            throw new DomainException($"Cannot start report in status {Status}.");
        Status = ReportExecutionStatus.Generating;
    }

    public void Complete(string fileUrl, long fileSizeBytes)
    {
        Status = ReportExecutionStatus.Completed;
        FileUrl = fileUrl;
        FileSizeBytes = fileSizeBytes;
        CompletedAt = DateTime.UtcNow;
    }

    public void Fail()
    {
        Status = ReportExecutionStatus.Failed;
        CompletedAt = DateTime.UtcNow;
    }

    public bool IsTerminal() =>
        Status is ReportExecutionStatus.Completed or ReportExecutionStatus.Failed;
}
