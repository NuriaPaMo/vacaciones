using FluentAssertions;
using IdentitySync.Domain.Graph;
using Xunit;

namespace IdentitySync.Domain.Tests.Graph;

// T010: AdUserMapper field mapping + role assignment from AD group membership
public class AdUserMapperTests
{
    private static AdUserDto BuildUser(
        string id = "ad-001",
        string? givenName = "Ana",
        string? surname = "García",
        string? mail = "ana.garcia@company.com",
        string? department = "Engineering",
        string? managerId = null,
        bool accountEnabled = true) =>
        new(id, givenName, surname, $"{givenName} {surname}", mail,
            department, JobTitle: null, accountEnabled, managerId);

    // ─── Field mapping ────────────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void MapToCommand_MapsAllFieldsCorrectly()
    {
        var user = BuildUser(id: "ad-123", givenName: "Carlos", surname: "Ruiz",
            mail: "Carlos.Ruiz@COMPANY.COM", department: "  Engineering  ");
        var cmd = AdUserMapper.MapToCommand(user, []);

        cmd.ExternalAdId.Should().Be("ad-123");
        cmd.FirstName.Should().Be("Carlos");
        cmd.LastName.Should().Be("Ruiz");
        cmd.Email.Should().Be("carlos.ruiz@company.com"); // lowercased
        cmd.Department.Should().Be("Engineering");        // trimmed
        cmd.AccountEnabled.Should().BeTrue();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void MapToCommand_WithNullMail_UsesEmptyString()
    {
        var user = new AdUserDto("ad-001", "Jane", "Doe", "Jane Doe",
            Mail: null, "HR", null, true, null);
        var cmd = AdUserMapper.MapToCommand(user, []);

        cmd.Email.Should().BeEmpty();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void MapToCommand_WithManagerId_PresentsManagerExternalAdId()
    {
        var user = BuildUser(managerId: "ad-manager-001");
        var cmd = AdUserMapper.MapToCommand(user, []);

        cmd.ManagerExternalAdId.Should().Be("ad-manager-001");
    }

    // ─── Role assignment from AD groups (BR-058) ──────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void MapToCommand_NoGroups_DefaultsToEmployee()
    {
        var cmd = AdUserMapper.MapToCommand(BuildUser(), []);
        cmd.Role.Should().Be(EmployeeRole.Employee);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void MapToCommand_InPMGroup_AssignsProjectManager()
    {
        var cmd = AdUserMapper.MapToCommand(BuildUser(),
            ["VacationSystem-ProjectManagers"]);
        cmd.Role.Should().Be(EmployeeRole.ProjectManager);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void MapToCommand_InDMGroup_AssignsDepartmentManager()
    {
        var cmd = AdUserMapper.MapToCommand(BuildUser(),
            ["VacationSystem-DepartmentManagers"]);
        cmd.Role.Should().Be(EmployeeRole.DepartmentManager);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void MapToCommand_InAdminGroup_AssignsAdministrator()
    {
        var cmd = AdUserMapper.MapToCommand(BuildUser(),
            ["VacationSystem-Admins"]);
        cmd.Role.Should().Be(EmployeeRole.Administrator);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void MapToCommand_InAdminAndPMGroups_AdminTakesPrecedence()
    {
        var cmd = AdUserMapper.MapToCommand(BuildUser(),
            ["VacationSystem-ProjectManagers", "VacationSystem-Admins"]);
        cmd.Role.Should().Be(EmployeeRole.Administrator);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void MapToCommand_GroupNameCaseInsensitive()
    {
        var cmd = AdUserMapper.MapToCommand(BuildUser(),
            ["VACATIONSYSTEM-PROJECTMANAGERS"]);
        cmd.Role.Should().Be(EmployeeRole.ProjectManager);
    }
}
