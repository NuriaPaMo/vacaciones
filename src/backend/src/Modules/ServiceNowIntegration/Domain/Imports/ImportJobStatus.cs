namespace ServiceNowIntegration.Domain.Imports;

public enum ImportJobStatus
{
    Running,
    Completed,
    CompletedWithErrors,
    Failed,
    Skipped  // circuit breaker open — BR-078
}
