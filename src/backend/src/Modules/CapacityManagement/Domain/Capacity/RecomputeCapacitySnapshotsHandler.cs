using CapacityManagement.Domain.Capacity.Events;
using CapacityManagement.Domain.Capacity.ValueObjects;
using VacationManagement.Domain.Common;

namespace CapacityManagement.Domain.Capacity;

// Port interfaces — implemented in Infrastructure layer
public interface ICapacitySnapshotRepository
{
    Task<CapacitySnapshot?> FindAsync(DateOnly date, OrganizationLevel level, Guid entityId, CancellationToken ct);
    Task UpsertAsync(CapacitySnapshot snapshot, CancellationToken ct);
}

public interface IThresholdConfigRepository
{
    // Returns dept-specific config if it exists, otherwise global (BR-124)
    Task<ThresholdConfig> GetEffectiveAsync(Guid? departmentId, CancellationToken ct);
    Task<ThresholdConfig?> FindGlobalAsync(CancellationToken ct);
    Task UpsertAsync(ThresholdConfig config, CancellationToken ct);
}

public interface IEmployeeHeadcountQuery
{
    // Returns (total, onVacation, pending) for the given org level and date
    Task<(int Total, int OnVacation, int Pending)> GetCountsAsync(
        Guid levelEntityId, OrganizationLevel level, DateOnly date, CancellationToken ct);
}

public interface IDomainEventPublisher
{
    Task PublishAsync(IDomainEvent @event, CancellationToken ct);
}

// ─── Handler ──────────────────────────────────────────────────────────────────

public sealed class RecomputeCapacitySnapshotsHandler
    : ICommandHandler<RecomputeCapacitySnapshotsCommand>
{
    private readonly ICapacitySnapshotRepository _snapshots;
    private readonly IThresholdConfigRepository _thresholds;
    private readonly IEmployeeHeadcountQuery _headcount;
    private readonly IDomainEventPublisher _publisher;

    public RecomputeCapacitySnapshotsHandler(
        ICapacitySnapshotRepository snapshots,
        IThresholdConfigRepository thresholds,
        IEmployeeHeadcountQuery headcount,
        IDomainEventPublisher publisher)
    {
        _snapshots = snapshots;
        _thresholds = thresholds;
        _headcount = headcount;
        _publisher = publisher;
    }

    public async Task HandleAsync(RecomputeCapacitySnapshotsCommand cmd, CancellationToken ct = default)
    {
        // Load the effective threshold for the given entity
        var deptId = cmd.Level == OrganizationLevel.Department ? cmd.LevelEntityId : (Guid?)null;
        var threshold = await _thresholds.GetEffectiveAsync(deptId, ct);

        var current = cmd.FromDate;
        while (current <= cmd.ToDate)
        {
            var (total, onVacation, pending) = await _headcount.GetCountsAsync(
                cmd.LevelEntityId, cmd.Level, current, ct);

            // INV-204: skip computation only if total is 0 (nothing to measure)
            if (total == 0)
            {
                current = current.AddDays(1);
                continue;
            }

            var existing = await _snapshots.FindAsync(current, cmd.Level, cmd.LevelEntityId, ct);
            bool wasCritical = existing?.IsCritical ?? false;
            bool wasWarning = existing?.IsWarning ?? false;

            if (existing is not null)
                existing.Recompute(total, onVacation, pending, threshold);
            else
                existing = CapacitySnapshot.Compute(
                    current, cmd.Level, cmd.LevelEntityId,
                    total, onVacation, pending, threshold);

            await _snapshots.UpsertAsync(existing, ct);

            // Publish threshold-crossed events (BR-098 dedup by checking previous state)
            if (existing.IsCritical && !wasCritical)
            {
                await _publisher.PublishAsync(new CapacityCriticalThresholdCrossed(
                    Guid.NewGuid(), DateTime.UtcNow,
                    cmd.LevelEntityId, current,
                    existing.CapacityPercentage, existing.EmployeesOnVacation + existing.EmployeesPending), ct);
            }
            else if (existing.IsWarning && !wasWarning)
            {
                await _publisher.PublishAsync(new CapacityWarningThresholdCrossed(
                    Guid.NewGuid(), DateTime.UtcNow,
                    cmd.LevelEntityId, current,
                    existing.CapacityPercentage, existing.EmployeesOnVacation + existing.EmployeesPending), ct);
            }

            current = current.AddDays(1);
        }

        // Signal cache invalidation to Redis consumers
        await _publisher.PublishAsync(new CapacitySnapshotInvalidated(
            Guid.NewGuid(), DateTime.UtcNow,
            cmd.Level, cmd.LevelEntityId, cmd.FromDate, cmd.ToDate), ct);
    }
}
