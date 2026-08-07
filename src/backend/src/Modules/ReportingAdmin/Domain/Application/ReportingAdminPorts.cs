using ReportingAdmin.Domain.Audit;
using ReportingAdmin.Domain.Configuration;
using ReportingAdmin.Domain.Reports;
using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;

namespace ReportingAdmin.Domain.Application;

// Port interfaces — implemented in Infrastructure

public interface IAuditEntryRepository
{
    // Append-only — no Update or Delete methods exposed
    Task AppendAsync(AuditEntry entry, CancellationToken ct);
}

public interface ISystemConfigurationRepository
{
    // Dept config overrides Global for same key (INV-613 / BR-124)
    Task<SystemConfiguration?> GetEffectiveAsync(string key, Guid? departmentId, CancellationToken ct);
    Task<IReadOnlyList<SystemConfiguration>> GetAllAsync(CancellationToken ct);
    Task UpsertAsync(SystemConfiguration config, CancellationToken ct);
}

public interface IReportExecutionRepository
{
    Task SaveAsync(ReportExecution execution, CancellationToken ct);
    Task<ReportExecution?> GetByIdAsync(Guid id, CancellationToken ct);
}

// IAuditContext provides the current user and source for every SaveChanges call
public interface IAuditContext
{
    EmployeeId? CurrentUserId { get; }
    string CurrentUserDisplayName { get; }
    AuditSource Source { get; }
}
