using ReportingAdmin.Domain.Audit;
using ReportingAdmin.Domain.Configuration;
using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;

namespace ReportingAdmin.Domain.Application;

// Command + handler for updating system configuration (US-027)
public sealed record UpdateSystemConfigurationCommand(
    string Key,
    string NewValue,
    ConfigScope Scope,
    Guid? DepartmentId,
    EmployeeId UpdatedBy);

public sealed class UpdateSystemConfigurationHandler
{
    private readonly ISystemConfigurationRepository _configs;
    private readonly IAuditEntryRepository _audit;

    public UpdateSystemConfigurationHandler(
        ISystemConfigurationRepository configs,
        IAuditEntryRepository audit)
    {
        _configs = configs;
        _audit = audit;
    }

    public async Task HandleAsync(UpdateSystemConfigurationCommand cmd, CancellationToken ct = default)
    {
        var existing = await _configs.GetEffectiveAsync(cmd.Key, cmd.DepartmentId, ct);

        SystemConfiguration config;
        string? oldValue = null;

        if (existing is not null && existing.Scope == cmd.Scope
            && existing.DepartmentId == cmd.DepartmentId)
        {
            oldValue = existing.Value;
            existing.Update(cmd.NewValue, cmd.UpdatedBy);
            config = existing;
        }
        else
        {
            config = cmd.Scope == ConfigScope.Global
                ? SystemConfiguration.CreateGlobal(cmd.Key, cmd.NewValue, cmd.UpdatedBy)
                : SystemConfiguration.CreateForDepartment(cmd.Key, cmd.NewValue, cmd.DepartmentId!.Value, cmd.UpdatedBy);
        }

        await _configs.UpsertAsync(config, ct);

        // Emit audit entry with before/after values (AC-027.5)
        await _audit.AppendAsync(AuditEntry.Create(
            cmd.UpdatedBy, "Administrator",
            AuditActionType.ConfigChanged,
            nameof(SystemConfiguration), config.Id.ToString(),
            oldValue is not null ? $"{{\"value\":\"{oldValue}\"}}" : null,
            $"{{\"value\":\"{cmd.NewValue}\"}}",
            AuditSource.UserAction,
            additionalContext: $"Key={cmd.Key} Scope={cmd.Scope}"), ct);
    }
}
