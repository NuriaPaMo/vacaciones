namespace ReportingAdmin.Domain.Audit;

public enum AuditSource
{
    UserAction,
    System,
    BackgroundJob,
    Integration
}
