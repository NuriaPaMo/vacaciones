using ServiceNowIntegration.Domain.Exports;
using ServiceNowIntegration.Domain.Http;
using ServiceNowIntegration.Domain.Imports;
using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;

namespace ServiceNowIntegration.Domain.Application;

// Domain event — published after each export batch
public sealed record ExportJobCompleted(
    Guid EventId,
    DateTime OccurredOn,
    Guid JobId,
    ExportJobStatus Status,
    int TotalExported,
    int TotalUpdated,
    int TotalDeleted,
    int ErrorCount,
    bool ExceedsErrorThreshold) : IDomainEvent;

// Domain event — published after each balance import
public sealed record ImportJobCompleted(
    Guid EventId,
    DateTime OccurredOn,
    Guid JobId,
    ImportJobStatus Status,
    int Updated,
    int ErrorCount) : IDomainEvent;

// Domain event — published when a record permanently fails (MaxRetriesExceeded)
public sealed record ExportRecordPermanentlyFailed(
    Guid EventId,
    DateTime OccurredOn,
    Guid ExportRecordId,
    VacationRequestId RequestId,
    string LastErrorMessage) : IDomainEvent;

// Port interfaces — implemented in Infrastructure
public interface IExportJobRepository
{
    Task<ExportJob?> GetRunningJobAsync(CancellationToken ct);
    Task SaveAsync(ExportJob job, CancellationToken ct);
}

public interface IImportJobRepository
{
    Task SaveAsync(ImportJob job, CancellationToken ct);
}

public interface IPendingVacationExportQuery
{
    // Delta query: Approved + IsExported=false (Create) OR Cancelled+IsExported=true (Delete)
    Task<IReadOnlyList<(VacationRequestId RequestId, ExportAction Action, string? ExistingSysId)>>
        GetPendingAsync(CancellationToken ct);
}

public interface IVacationExportDetailsQuery
{
    // Provides the DTO fields for a specific vacation request
    Task<VacationExportDto> GetDetailsAsync(VacationRequestId requestId, CancellationToken ct);
}

public interface IVacationRequestExportStateUpdater
{
    Task MarkExportedAsync(VacationRequestId requestId, string serviceNowId, CancellationToken ct);
}

public interface IEmployeeBalanceUpdater
{
    Task UpdateBalanceAsync(string employeeAdId, int totalDays, int usedDays, CancellationToken ct);
}

public interface IDomainEventPublisher
{
    Task PublishAsync(IDomainEvent @event, CancellationToken ct);
}
