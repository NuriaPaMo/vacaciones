using VacationManagement.Domain.VacationRequests.ValueObjects;

namespace IdentitySync.Domain.Graph;

// Field-mapping specification from data-model.md
// Role assignment from AD group names (BR-058)
public static class AdUserMapper
{
    // AD group names that grant elevated roles (must match real AD group display names)
    private const string DmGroupName = "VacationSystem-DepartmentManagers";
    private const string PmGroupName = "VacationSystem-ProjectManagers";
    private const string AdminGroupName = "VacationSystem-Admins";

    public static UpsertEmployeeCommand MapToCommand(
        AdUserDto user, IReadOnlyList<string> groupNames) =>
        new(
            ExternalAdId: user.Id,
            FirstName: user.GivenName?.Trim() ?? string.Empty,
            LastName: user.Surname?.Trim() ?? string.Empty,
            Email: (user.Mail ?? string.Empty).ToLowerInvariant(),
            Department: user.Department?.Trim() ?? string.Empty,
            ManagerExternalAdId: user.ManagerId,
            AccountEnabled: user.AccountEnabled,
            Role: DetermineRole(groupNames));

    private static EmployeeRole DetermineRole(IReadOnlyList<string> groupNames)
    {
        if (groupNames.Contains(AdminGroupName, StringComparer.OrdinalIgnoreCase))
            return EmployeeRole.Administrator;
        if (groupNames.Contains(DmGroupName, StringComparer.OrdinalIgnoreCase))
            return EmployeeRole.DepartmentManager;
        if (groupNames.Contains(PmGroupName, StringComparer.OrdinalIgnoreCase))
            return EmployeeRole.ProjectManager;
        return EmployeeRole.Employee;
    }
}

// Typed command — carries one AD user record into the upsert handler
public sealed record UpsertEmployeeCommand(
    string ExternalAdId,
    string FirstName,
    string LastName,
    string Email,
    string Department,
    string? ManagerExternalAdId,
    bool AccountEnabled,
    EmployeeRole Role);

// Employee role enum — must match VacationManagement.Domain.VacationRequests.ValueObjects
// Defined here to avoid cross-module coupling; kept in sync by convention
public enum EmployeeRole
{
    Employee,
    ProjectManager,
    DepartmentManager,
    Administrator
}
