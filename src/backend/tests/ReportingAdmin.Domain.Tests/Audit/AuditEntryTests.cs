using FluentAssertions;
using ReportingAdmin.Domain.Audit;
using ReportingAdmin.Domain.Configuration;
using VacationManagement.Domain.VacationRequests.ValueObjects;
using Xunit;

namespace ReportingAdmin.Domain.Tests.Audit;

// T011: AuditEntry immutability; AuditableChange serialisation; AuditRedact attribute usage
// T012: UpdateSystemConfigurationCommand validation + PreviousValue capture
public class AuditEntryTests
{
    private static readonly EmployeeId User = EmployeeId.New();

    // ─── AuditEntry factory ───────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void AuditEntry_Create_SetsUtcTimestampAndAllFields()
    {
        var entry = AuditEntry.Create(
            User, "Carlos Ruiz",
            AuditActionType.Created,
            "VacationRequest", Guid.NewGuid().ToString(),
            oldValuesJson: null,
            newValuesJson: "{\"status\":\"Pending\"}",
            AuditSource.UserAction);

        entry.Id.Should().NotBeEmpty();
        entry.Timestamp.Kind.Should().Be(DateTimeKind.Utc);     // INV-602
        entry.ActionType.Should().Be(AuditActionType.Created);
        entry.OldValuesJson.Should().BeNull();
        entry.NewValuesJson.Should().Be("{\"status\":\"Pending\"}");
        entry.Source.Should().Be(AuditSource.UserAction);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void AuditEntry_Create_WithSystemUser_UserIdIsNull()
    {
        var entry = AuditEntry.Create(
            null, "System",
            AuditActionType.Exported,
            "ExportJob", Guid.NewGuid().ToString(),
            null, null, AuditSource.BackgroundJob);

        entry.UserId.Should().BeNull();
        entry.UserDisplayName.Should().Be("System");
        entry.Source.Should().Be(AuditSource.BackgroundJob);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void AuditEntry_WithBothOldAndNewValues_StoresBothCorrectly()
    {
        var entry = AuditEntry.Create(
            User, "Ana García",
            AuditActionType.StatusChanged,
            "VacationRequest", "REQ-001",
            oldValuesJson: "{\"status\":\"Pending\"}",
            newValuesJson: "{\"status\":\"Approved\"}",
            AuditSource.UserAction);

        entry.OldValuesJson.Should().Contain("Pending");
        entry.NewValuesJson.Should().Contain("Approved");
        entry.ActionType.Should().Be(AuditActionType.StatusChanged);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void AuditEntry_WithAdditionalContext_StoresIt()
    {
        var entry = AuditEntry.Create(
            User, "Admin", AuditActionType.ConfigChanged,
            "SystemConfiguration", "cfg-001",
            null, null, AuditSource.UserAction,
            additionalContext: "Key=critical_threshold Scope=Global");

        entry.AdditionalContext.Should().Contain("critical_threshold");
    }

    // ─── AuditRedact attribute ────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void AuditRedactAttribute_CanBeAppliedToProperty()
    {
        var attr = typeof(SampleEntityWithPii)
            .GetProperty(nameof(SampleEntityWithPii.Email))!
            .GetCustomAttributes(typeof(AuditRedactAttribute), false);

        attr.Should().NotBeEmpty();
    }

    private sealed class SampleEntityWithPii
    {
        [AuditRedact]
        public string Email { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
    }

    // ─── AuditableChange serialisation ────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void AuditableChange_Serialise_ProducesValidJson()
    {
        var change = new Application.AuditableChange(
            "VacationRequest", "REQ-001",
            AuditActionType.StatusChanged,
            OldValues: new() { ["status"] = "Pending" },
            NewValues: new() { ["status"] = "Approved" });

        change.SerialiseOldValues().Should().Contain("Pending");
        change.SerialiseNewValues().Should().Contain("Approved");
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void AuditableChange_NullValues_SerialiseToNull()
    {
        var change = new Application.AuditableChange(
            "ExportJob", "JOB-001", AuditActionType.Created,
            OldValues: null, NewValues: null);

        change.SerialiseOldValues().Should().BeNull();
        change.SerialiseNewValues().Should().BeNull();
    }
}
