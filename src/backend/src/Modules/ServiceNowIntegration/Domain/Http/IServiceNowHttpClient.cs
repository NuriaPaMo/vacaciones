using VacationManagement.Domain.Common;

namespace ServiceNowIntegration.Domain.Http;

// Port interface — concrete implementation uses HttpClient + Polly + ServiceNowAuthHandler
// All secrets read from Azure Key Vault via Managed Identity (T016-QG: 0 hardcoded secrets)
public interface IServiceNowHttpClient
{
    /// POST to ServiceNow Table API. Returns the new record's sys_id on success.
    Task<string> PostAsync(string tableName, object payload, CancellationToken ct = default);

    /// PATCH an existing ServiceNow record.
    Task UpdateAsync(string tableName, string sysId, object payload, CancellationToken ct = default);

    /// DELETE a ServiceNow record by sys_id.
    Task DeleteAsync(string tableName, string sysId, CancellationToken ct = default);

    /// GET a page of records from a ServiceNow table. Returns (rows, nextPageToken).
    Task<(IReadOnlyList<Dictionary<string, string>> Rows, string? NextPageToken)>
        GetPageAsync(string tableName, string? pageToken, CancellationToken ct = default);
}

// DTO sent to ServiceNow for vacation records
// ⚠ Q-013: exact table name and field names to be confirmed with ServiceNow team before UAT
public sealed record VacationExportDto(
    string EmployeeName,
    string EmployeeAdId,
    string StartDate,
    string EndDate,
    int TotalDays,
    string Status,
    string DepartmentName,
    string InternalRequestId);

// DTO received from ServiceNow for vacation balance import
public sealed record VacationBalanceDto(
    string EmployeeAdId,
    int TotalDays,
    int UsedDays,
    int PendingDays);
