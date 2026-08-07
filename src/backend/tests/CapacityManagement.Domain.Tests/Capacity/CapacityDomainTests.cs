using CapacityManagement.Domain.Capacity;
using CapacityManagement.Domain.Capacity.ValueObjects;
using FluentAssertions;
using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;
using Xunit;

namespace CapacityManagement.Domain.Tests.Capacity;

// T011: CapacityColor boundaries, ThresholdConfig dept-override, CapacityPeriod, AlternativeDateSuggestion
public class CapacityDomainTests
{
    private static readonly EmployeeId SystemUser = EmployeeId.New();

    // ─── CapacityColor.FromPercentage (BR-040) ────────────────────────────────

    [Theory]
    [InlineData(0, "Green")]
    [InlineData(25, "Green")]
    [InlineData(50, "Green")]   // boundary: 50% = Green
    [InlineData(51, "Yellow")]  // boundary: 51% = Yellow
    [InlineData(60, "Yellow")]
    [InlineData(64, "Yellow")]  // boundary: 64% = Yellow
    [InlineData(65, "Orange")]  // boundary: 65% = Orange (WarningThreshold)
    [InlineData(68, "Orange")]
    [InlineData(70, "Orange")]  // boundary: 70% = Orange (CriticalThreshold)
    [InlineData(71, "Red")]     // boundary: 71% = Red (>CriticalThreshold)
    [InlineData(80, "Red")]
    [InlineData(100, "Red")]
    [Trait("Category", "Unit")]
    public void FromPercentage_ReturnsCorrectColor(decimal pct, string expected)
    {
        var threshold = ThresholdConfig.Default(SystemUser);
        var color = CapacityColorExtensions.FromPercentage(pct, threshold);
        color.ToString().Should().Be(expected);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void FromPercentage_WithCustomThreshold_RespectsDeptConfig()
    {
        // Dept override: warning=60, critical=75
        var deptId = Guid.NewGuid();
        var config = ThresholdConfig.CreateForDepartment(deptId, 60, 75, SystemUser);

        CapacityColorExtensions.FromPercentage(59m, config).Should().Be(CapacityColor.Yellow);
        CapacityColorExtensions.FromPercentage(60m, config).Should().Be(CapacityColor.Orange);
        CapacityColorExtensions.FromPercentage(75m, config).Should().Be(CapacityColor.Orange);
        CapacityColorExtensions.FromPercentage(76m, config).Should().Be(CapacityColor.Red);
    }

    // ─── ThresholdConfig invariants ───────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void ThresholdConfig_Default_HasExpectedValues()
    {
        var config = ThresholdConfig.Default(SystemUser);
        config.WarningThresholdPct.Should().Be(65);
        config.CriticalThresholdPct.Should().Be(70);
        config.Scope.Should().Be(ThresholdScope.Global);
    }

    [Theory]
    [InlineData(0, 70)]   // warning = 0 → invalid
    [InlineData(101, 70)] // warning = 101 → invalid
    [InlineData(65, 0)]   // critical = 0 → invalid
    [InlineData(65, 65)]  // critical = warning → not strictly greater
    [InlineData(70, 65)]  // critical < warning → invalid
    [Trait("Category", "Unit")]
    public void ThresholdConfig_InvalidValues_ThrowDomainException(int warning, int critical)
    {
        var act = () => ThresholdConfig.CreateGlobal(warning, critical, SystemUser);
        act.Should().Throw<DomainException>();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void ThresholdConfig_ValidBoundaryValues_Succeeds()
    {
        ThresholdConfig.CreateGlobal(1, 2, SystemUser).Should().NotBeNull();
        ThresholdConfig.CreateGlobal(99, 100, SystemUser).Should().NotBeNull();
    }

    // ─── IsApplicableTo — dept override > global (BR-124) ────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void GlobalConfig_IsApplicableToAnyDepartment()
    {
        var global = ThresholdConfig.Default(SystemUser);
        global.IsApplicableTo(Guid.NewGuid()).Should().BeTrue();
        global.IsApplicableTo(null).Should().BeTrue();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void DeptConfig_OnlyApplicableToMatchingDepartment()
    {
        var deptId = Guid.NewGuid();
        var deptConfig = ThresholdConfig.CreateForDepartment(deptId, 60, 75, SystemUser);

        deptConfig.IsApplicableTo(deptId).Should().BeTrue();
        deptConfig.IsApplicableTo(Guid.NewGuid()).Should().BeFalse();
        deptConfig.IsApplicableTo(null).Should().BeFalse();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void ThresholdConfig_Update_ChangesValuesAndTimestamp()
    {
        var config = ThresholdConfig.Default(SystemUser);
        var before = config.UpdatedAt;

        config.Update(60, 80, SystemUser);

        config.WarningThresholdPct.Should().Be(60);
        config.CriticalThresholdPct.Should().Be(80);
        config.UpdatedAt.Should().BeOnOrAfter(before);
    }

    // ─── CapacityPeriod.GetDates ──────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void CapacityPeriod_Daily_ReturnsEveryDay()
    {
        var period = CapacityPeriod.Create(
            new DateOnly(2026, 8, 10),
            new DateOnly(2026, 8, 12),
            CapacityGranularity.Daily);

        var dates = period.GetDates().ToList();
        dates.Should().HaveCount(3);
        dates[0].Should().Be(new DateOnly(2026, 8, 10));
        dates[2].Should().Be(new DateOnly(2026, 8, 12));
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void CapacityPeriod_Weekly_ReturnsMondaysOnly()
    {
        var period = CapacityPeriod.Create(
            new DateOnly(2026, 8, 10),  // Monday
            new DateOnly(2026, 8, 24),  // ends on a Monday
            CapacityGranularity.Weekly);

        var dates = period.GetDates().ToList();
        dates.Should().OnlyContain(d => d.DayOfWeek == DayOfWeek.Monday);
        dates.Should().HaveCount(3); // 10, 17, 24
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void CapacityPeriod_Create_StartAfterEnd_ThrowsDomainException()
    {
        var act = () => CapacityPeriod.Create(
            new DateOnly(2026, 8, 14),
            new DateOnly(2026, 8, 10));
        act.Should().Throw<DomainException>();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void CapacityPeriod_Next90Days_HasCorrectRange()
    {
        var from = new DateOnly(2026, 8, 7);
        var period = CapacityPeriod.Next90Days(from);

        period.StartDate.Should().Be(from);
        period.EndDate.Should().Be(from.AddDays(90));
    }

    // ─── CapacitySnapshot.Compute ─────────────────────────────────────────────

    [Theory]
    [InlineData(10, 5, 2, 70, false, true)]   // 70% = IsWarning (65≤pct≤70)
    [InlineData(10, 8, 0, 80, true, false)]   // 80% = IsCritical
    [InlineData(10, 4, 1, 50, false, false)]  // 50% = Green, neither
    [InlineData(10, 7, 0, 70, false, true)]   // exactly 70% = IsWarning
    [InlineData(10, 7, 1, 80, true, false)]   // 80% = IsCritical
    [Trait("Category", "Unit")]
    public void CapacitySnapshot_Compute_SetsCorrectFlags(
        int total, int onVacation, int pending,
        decimal expectedPct, bool expectedCritical, bool expectedWarning)
    {
        var threshold = ThresholdConfig.Default(SystemUser);
        var snapshot = CapacitySnapshot.Compute(
            new DateOnly(2026, 8, 10),
            OrganizationLevel.Department,
            Guid.NewGuid(),
            total, onVacation, pending,
            threshold);

        snapshot.CapacityPercentage.Should().Be(expectedPct);
        snapshot.IsCritical.Should().Be(expectedCritical);
        snapshot.IsWarning.Should().Be(expectedWarning);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void CapacitySnapshot_WhenTotalIsZero_ReturnsZeroPercent()
    {
        var threshold = ThresholdConfig.Default(SystemUser);
        var snapshot = CapacitySnapshot.Compute(
            new DateOnly(2026, 8, 10), OrganizationLevel.Department, Guid.NewGuid(),
            0, 0, 0, threshold);

        snapshot.CapacityPercentage.Should().Be(0m);
        snapshot.IsCritical.Should().BeFalse();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void CapacitySnapshot_Recompute_UpdatesAllFields()
    {
        var threshold = ThresholdConfig.Default(SystemUser);
        var entityId = Guid.NewGuid();
        var snapshot = CapacitySnapshot.Compute(
            new DateOnly(2026, 8, 10), OrganizationLevel.Department, entityId,
            10, 2, 0, threshold);

        snapshot.CapacityPercentage.Should().Be(20m);

        snapshot.Recompute(10, 8, 0, threshold); // now 80% = critical

        snapshot.CapacityPercentage.Should().Be(80m);
        snapshot.IsCritical.Should().BeTrue();
        snapshot.IsWarning.Should().BeFalse();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void CapacitySnapshot_IsSameSlot_MatchesOnAllThreeKeys()
    {
        var date = new DateOnly(2026, 8, 10);
        var entityId = Guid.NewGuid();
        var threshold = ThresholdConfig.Default(SystemUser);

        var snapshot = CapacitySnapshot.Compute(
            date, OrganizationLevel.Department, entityId, 10, 3, 0, threshold);

        snapshot.IsSameSlot(date, OrganizationLevel.Department, entityId).Should().BeTrue();
        snapshot.IsSameSlot(date, OrganizationLevel.Project, entityId).Should().BeFalse();
        snapshot.IsSameSlot(date.AddDays(1), OrganizationLevel.Department, entityId).Should().BeFalse();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void CapacitySnapshot_NegativeInputs_ThrowDomainException()
    {
        var threshold = ThresholdConfig.Default(SystemUser);
        var act = () => CapacitySnapshot.Compute(
            new DateOnly(2026, 8, 10), OrganizationLevel.Department, Guid.NewGuid(),
            -1, 0, 0, threshold);
        act.Should().Throw<DomainException>();
    }

    // ─── AlternativeDateSuggestion ────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void AlternativeDateSuggestion_RecordsProjectedValues()
    {
        var suggestion = new AlternativeDateSuggestion(
            new DateOnly(2026, 9, 1),
            new DateOnly(2026, 9, 5),
            20m,
            CapacityColor.Green);

        suggestion.SuggestedStart.Should().Be(new DateOnly(2026, 9, 1));
        suggestion.ProjectedCapacityPercent.Should().Be(20m);
        suggestion.ProjectedColor.Should().Be(CapacityColor.Green);
    }
}
