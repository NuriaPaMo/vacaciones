using FluentAssertions;
using ReportingAdmin.Domain.Application;
using ReportingAdmin.Domain.Audit;
using ReportingAdmin.Domain.Configuration;
using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;
using Xunit;

namespace ReportingAdmin.Domain.Tests.Configuration;

// T012: UpdateSystemConfigurationCommand — validation, PreviousValue capture, audit entry generated
public class SystemConfigurationTests
{
    private static readonly EmployeeId Admin = EmployeeId.New();

    // ─── SystemConfiguration aggregate ───────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void CreateGlobal_SetsCorrectScope()
    {
        var config = SystemConfiguration.CreateGlobal("capacity.critical", "70", Admin);

        config.Scope.Should().Be(ConfigScope.Global);
        config.DepartmentId.Should().BeNull();
        config.Value.Should().Be("70");
        config.PreviousValue.Should().BeNull();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void CreateForDepartment_SetsDepartmentScope()
    {
        var deptId = Guid.NewGuid();
        var config = SystemConfiguration.CreateForDepartment("capacity.critical", "75", deptId, Admin);

        config.Scope.Should().Be(ConfigScope.Department);
        config.DepartmentId.Should().Be(deptId);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Update_CapturesPreviousValue()
    {
        var config = SystemConfiguration.CreateGlobal("threshold", "70", Admin);

        config.Update("75", Admin);

        config.Value.Should().Be("75");
        config.PreviousValue.Should().Be("70");   // AC-027.5
        config.UpdatedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(2));
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Update_Twice_PreviousValueReflectsLastUpdate()
    {
        var config = SystemConfiguration.CreateGlobal("threshold", "65", Admin);
        config.Update("70", Admin);
        config.Update("75", Admin);

        config.Value.Should().Be("75");
        config.PreviousValue.Should().Be("70");  // second update overwrites first PreviousValue
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void GetValue_DeserialisesBoolCorrectly()
    {
        var config = SystemConfiguration.CreateGlobal("feature.enabled", "true", Admin);
        config.GetValue<bool>().Should().BeTrue();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void GetValue_DeserialiseIntCorrectly()
    {
        var config = SystemConfiguration.CreateGlobal("capacity.critical", "70", Admin);
        config.GetValue<int>().Should().Be(70);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void IsApplicableTo_GlobalConfig_TrueForAnyDepartment()
    {
        var config = SystemConfiguration.CreateGlobal("key", "val", Admin);
        config.IsApplicableTo(Guid.NewGuid()).Should().BeTrue();
        config.IsApplicableTo(null).Should().BeTrue();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void IsApplicableTo_DeptConfig_OnlyMatchingDept()
    {
        var deptId = Guid.NewGuid();
        var config = SystemConfiguration.CreateForDepartment("key", "val", deptId, Admin);

        config.IsApplicableTo(deptId).Should().BeTrue();
        config.IsApplicableTo(Guid.NewGuid()).Should().BeFalse();
        config.IsApplicableTo(null).Should().BeFalse();
    }

    // ─── UpdateSystemConfigurationHandler ─────────────────────────────────────

    private sealed class FakeConfigRepo : ISystemConfigurationRepository
    {
        private readonly Dictionary<string, SystemConfiguration> _store = new();

        public Task<SystemConfiguration?> GetEffectiveAsync(
            string key, Guid? departmentId, CancellationToken ct)
        {
            _store.TryGetValue(KeyOf(key, departmentId), out var v);
            return Task.FromResult(v);
        }

        public Task<IReadOnlyList<SystemConfiguration>> GetAllAsync(CancellationToken ct) =>
            Task.FromResult<IReadOnlyList<SystemConfiguration>>(_store.Values.ToList());

        public Task UpsertAsync(SystemConfiguration c, CancellationToken ct)
        {
            _store[KeyOf(c.Key, c.DepartmentId)] = c;
            return Task.CompletedTask;
        }

        private static string KeyOf(string key, Guid? deptId) => $"{key}|{deptId}";
        public IReadOnlyDictionary<string, SystemConfiguration> All => _store;
    }

    private sealed class FakeAuditRepo : IAuditEntryRepository
    {
        public List<AuditEntry> Entries { get; } = [];
        public Task AppendAsync(AuditEntry e, CancellationToken _) { Entries.Add(e); return Task.CompletedTask; }
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Handle_NewGlobalConfig_CreatesAndAudits()
    {
        var configRepo = new FakeConfigRepo();
        var auditRepo = new FakeAuditRepo();
        var handler = new UpdateSystemConfigurationHandler(configRepo, auditRepo);

        await handler.HandleAsync(new UpdateSystemConfigurationCommand(
            "capacity.critical", "70", ConfigScope.Global, null, Admin));

        configRepo.All.Should().ContainKey("capacity.critical|");
        configRepo.All["capacity.critical|"].Value.Should().Be("70");
        auditRepo.Entries.Should().ContainSingle(e => e.ActionType == AuditActionType.ConfigChanged);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Handle_UpdateExistingConfig_CapturesPreviousValueInAudit()
    {
        var configRepo = new FakeConfigRepo();
        var auditRepo = new FakeAuditRepo();
        var handler = new UpdateSystemConfigurationHandler(configRepo, auditRepo);

        // First create
        await handler.HandleAsync(new UpdateSystemConfigurationCommand(
            "capacity.critical", "70", ConfigScope.Global, null, Admin));

        // Then update
        await handler.HandleAsync(new UpdateSystemConfigurationCommand(
            "capacity.critical", "75", ConfigScope.Global, null, Admin));

        configRepo.All["capacity.critical|"].Value.Should().Be("75");
        configRepo.All["capacity.critical|"].PreviousValue.Should().Be("70");

        var latestAudit = auditRepo.Entries.Last();
        latestAudit.OldValuesJson.Should().Contain("70");
        latestAudit.NewValuesJson.Should().Contain("75");
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Handle_DepartmentOverride_CreatesWithDepartmentScope()
    {
        var deptId = Guid.NewGuid();
        var configRepo = new FakeConfigRepo();
        var handler = new UpdateSystemConfigurationHandler(configRepo, new FakeAuditRepo());

        await handler.HandleAsync(new UpdateSystemConfigurationCommand(
            "capacity.critical", "80", ConfigScope.Department, deptId, Admin));

        configRepo.All[$"capacity.critical|{deptId}"].Scope.Should().Be(ConfigScope.Department);
    }

    // ─── ReportExecution lifecycle ─────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void ReportExecution_Create_SetsQueuedStatus()
    {
        var exec = Reports.ReportExecution.Create(
            Reports.ReportType.VacationHistory,
            Reports.ReportFormat.Excel,
            "{}", Admin);

        exec.Status.Should().Be(Reports.ReportExecutionStatus.Queued);
        exec.IsTerminal().Should().BeFalse();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void ReportExecution_Complete_SetsCompletedAndFileUrl()
    {
        var exec = Reports.ReportExecution.Create(
            Reports.ReportType.VacationHistory,
            Reports.ReportFormat.Csv,
            "{}", Admin);

        exec.StartGenerating();
        exec.Complete("https://blob.azure.com/report.csv", 1024L);

        exec.Status.Should().Be(Reports.ReportExecutionStatus.Completed);
        exec.FileUrl.Should().Contain(".csv");
        exec.FileSizeBytes.Should().Be(1024L);
        exec.IsTerminal().Should().BeTrue();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void ReportExecution_Fail_SetsFailedStatus()
    {
        var exec = Reports.ReportExecution.Create(
            Reports.ReportType.AuditLog, Reports.ReportFormat.Pdf, "{}", Admin);
        exec.StartGenerating();
        exec.Fail();

        exec.Status.Should().Be(Reports.ReportExecutionStatus.Failed);
        exec.IsTerminal().Should().BeTrue();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void ReportExecution_StartGenerating_WhenNotQueued_ThrowsDomainException()
    {
        var exec = Reports.ReportExecution.Create(
            Reports.ReportType.Coverage, Reports.ReportFormat.Csv, "{}", Admin);
        exec.StartGenerating();

        var act = () => exec.StartGenerating();
        act.Should().Throw<DomainException>();
    }
}
