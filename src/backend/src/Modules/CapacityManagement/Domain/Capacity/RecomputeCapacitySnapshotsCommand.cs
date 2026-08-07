using CapacityManagement.Domain.Capacity.ValueObjects;
using VacationManagement.Domain.Common;

namespace CapacityManagement.Domain.Capacity;

// CQRS command — triggers a full recomputation for a date range and org level
public sealed record RecomputeCapacitySnapshotsCommand(
    Guid LevelEntityId,
    OrganizationLevel Level,
    DateOnly FromDate,
    DateOnly ToDate) : ICommand;

// Marker interfaces (replicate constitution binding contracts locally to avoid circular deps)
// In the full solution these would come from the shared Infrastructure/Cqrs project
public interface ICommand { }

public interface ICommandHandler<in TCommand> where TCommand : ICommand
{
    Task HandleAsync(TCommand command, CancellationToken ct = default);
}
