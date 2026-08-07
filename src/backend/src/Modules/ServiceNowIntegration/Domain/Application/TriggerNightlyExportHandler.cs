using ServiceNowIntegration.Domain.Exports;
using ServiceNowIntegration.Domain.Http;
using VacationManagement.Domain.Common;

namespace ServiceNowIntegration.Domain.Application;

// Orchestrates the nightly export batch (runs at 4AM after AD sync completes)
// BR-071: only Approved requests exported
// BR-072: delta sync — new or changed since last successful export
// BR-075: failed records do not block others (INV-403)
// BR-081: alert if errorRate > 5%
public sealed class TriggerNightlyExportHandler
{
    // ⚠ Q-013: table name TBC with ServiceNow team — placeholder until confirmed
    private const string VacationTableName = "u_vacation_requests";

    private readonly IPendingVacationExportQuery _pending;
    private readonly IVacationExportDetailsQuery _details;
    private readonly IVacationRequestExportStateUpdater _stateUpdater;
    private readonly IServiceNowHttpClient _serviceNow;
    private readonly IExportJobRepository _jobs;
    private readonly IDomainEventPublisher _publisher;

    public TriggerNightlyExportHandler(
        IPendingVacationExportQuery pending,
        IVacationExportDetailsQuery details,
        IVacationRequestExportStateUpdater stateUpdater,
        IServiceNowHttpClient serviceNow,
        IExportJobRepository jobs,
        IDomainEventPublisher publisher)
    {
        _pending = pending;
        _details = details;
        _stateUpdater = stateUpdater;
        _serviceNow = serviceNow;
        _jobs = jobs;
        _publisher = publisher;
    }

    public async Task<ExportJob> ExecuteAsync(CancellationToken ct = default)
    {
        var job = ExportJob.Start();
        await _jobs.SaveAsync(job, ct);

        var pendingRecords = await _pending.GetPendingAsync(ct);

        foreach (var (requestId, action, existingSysId) in pendingRecords)
        {
            var exportRecord = job.AddRecord(requestId, action);

            try
            {
                string sysId;
                switch (action)
                {
                    case ExportAction.Create:
                        var dto = await _details.GetDetailsAsync(requestId, ct);
                        sysId = await _serviceNow.PostAsync(VacationTableName, dto, ct);
                        await _stateUpdater.MarkExportedAsync(requestId, sysId, ct);
                        job.RecordSuccess(exportRecord.Id, sysId);
                        break;

                    case ExportAction.Delete:
                        await _serviceNow.DeleteAsync(VacationTableName, existingSysId!, ct);
                        job.RecordSuccess(exportRecord.Id, existingSysId!);
                        break;

                    case ExportAction.Update:
                        var updateDto = await _details.GetDetailsAsync(requestId, ct);
                        await _serviceNow.UpdateAsync(VacationTableName, existingSysId!, updateDto, ct);
                        job.RecordSuccess(exportRecord.Id, existingSysId!);
                        break;
                }
            }
            catch (Exception ex)
            {
                // INV-403 / BR-075: failure does not stop batch
                job.RecordFailure(exportRecord.Id, ex.Message);

                if (exportRecord.Status == ExportRecordStatus.MaxRetriesExceeded)
                {
                    await _publisher.PublishAsync(new ExportRecordPermanentlyFailed(
                        Guid.NewGuid(), DateTime.UtcNow,
                        exportRecord.Id, requestId, ex.Message), ct);
                }
            }
        }

        job.Complete();
        await _jobs.SaveAsync(job, ct);

        await _publisher.PublishAsync(new ExportJobCompleted(
            Guid.NewGuid(), DateTime.UtcNow,
            job.Id, job.Status,
            job.TotalExported, job.TotalUpdated, job.TotalDeleted, job.ErrorCount,
            job.ExceedsErrorThreshold()), ct);

        return job;
    }
}
