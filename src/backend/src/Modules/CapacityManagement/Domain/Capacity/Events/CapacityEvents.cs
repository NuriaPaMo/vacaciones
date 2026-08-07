using CapacityManagement.Domain.Capacity.ValueObjects;
using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;

namespace CapacityManagement.Domain.Capacity.Events;

// Published when a period first crosses the warning threshold (65–70%)
// BR-098: one alert per (department, period, level) per crossing
public sealed record CapacityWarningThresholdCrossed(
    Guid EventId,
    DateTime OccurredOn,
    Guid DepartmentId,
    DateOnly AffectedDate,
    decimal CapacityPercent,
    int EmployeeCount) : IDomainEvent;

// Published when a period exceeds the critical threshold (>70%)
public sealed record CapacityCriticalThresholdCrossed(
    Guid EventId,
    DateTime OccurredOn,
    Guid DepartmentId,
    DateOnly AffectedDate,
    decimal CapacityPercent,
    int EmployeeCount) : IDomainEvent;

// Published after recomputation to signal Redis cache invalidation consumers
public sealed record CapacitySnapshotInvalidated(
    Guid EventId,
    DateTime OccurredOn,
    OrganizationLevel Level,
    Guid LevelEntityId,
    DateOnly FromDate,
    DateOnly ToDate) : IDomainEvent;
