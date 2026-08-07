namespace ReportingAdmin.Domain.Audit;

// 15 action types covering all state-changing operations across every module
public enum AuditActionType
{
    Created,
    Updated,
    Deleted,
    StatusChanged,
    Approved,
    Rejected,
    Cancelled,
    Delegated,
    Escalated,
    Exported,
    Imported,
    ConfigChanged,
    RoleChanged,
    LoginSuccess,
    LoginFailed
}
