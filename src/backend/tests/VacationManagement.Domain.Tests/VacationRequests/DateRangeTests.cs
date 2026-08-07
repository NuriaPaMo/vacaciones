using FluentAssertions;
using VacationManagement.Domain.VacationRequests.ValueObjects;
using Xunit;

namespace VacationManagement.Domain.Tests.VacationRequests;

// T007: 20+ parameterized cases covering BR-003 (Mon–Fri only, inclusive)
public class DateRangeTests
{
    [Theory]
    [InlineData("2026-08-10", "2026-08-14", 5)]  // Mon–Fri full week
    [InlineData("2026-08-10", "2026-08-10", 1)]  // single Mon
    [InlineData("2026-08-14", "2026-08-14", 1)]  // single Fri
    [InlineData("2026-08-10", "2026-08-16", 5)]  // Mon → Sun, skips Sat+Sun
    [InlineData("2026-08-14", "2026-08-17", 2)]  // Fri → Mon, skips Sat+Sun
    [InlineData("2026-08-10", "2026-08-21", 10)] // two full weeks
    [InlineData("2026-08-31", "2026-09-04", 5)]  // cross-month Mon–Fri
    [InlineData("2026-09-30", "2026-10-02", 3)]  // cross-month Wed → Fri
    [InlineData("2026-12-28", "2027-01-02", 5)]  // cross-year Mon → Sat (4+1)
    [InlineData("2026-08-15", "2026-08-16", 0)]  // Sat–Sun only
    [InlineData("2026-08-15", "2026-08-15", 0)]  // Sat only
    [InlineData("2026-08-16", "2026-08-16", 0)]  // Sun only
    [InlineData("2026-08-11", "2026-08-11", 1)]  // single Tue
    [InlineData("2026-08-12", "2026-08-12", 1)]  // single Wed
    [InlineData("2026-08-13", "2026-08-13", 1)]  // single Thu
    [InlineData("2026-08-10", "2026-09-11", 25)] // 5 full weeks
    [InlineData("2026-01-01", "2026-01-01", 1)]  // Jan 1 Thu — no holiday exclusion in BR-003
    [InlineData("2026-08-17", "2026-08-21", 5)]  // Mon–Fri following week
    [InlineData("2026-09-07", "2026-09-07", 1)]  // single Mon (September)
    [InlineData("2026-11-30", "2026-12-04", 5)]  // Mon–Fri across Nov/Dec boundary
    [Trait("Category", "Unit")]
    public void CalculateBusinessDays_ReturnsExpected(string start, string end, int expected)
    {
        var range = DateRange.Create(DateOnly.Parse(start), DateOnly.Parse(end));
        range.TotalBusinessDays.Should().Be(expected);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Create_WhenStartAfterEnd_ThrowsDomainException()
    {
        var act = () => DateRange.Create(
            new DateOnly(2026, 8, 14),
            new DateOnly(2026, 8, 10));

        act.Should().Throw<Common.DomainException>()
            .WithMessage("*Start date must be before or equal to end date*");
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Create_WhenSameDay_Succeeds()
    {
        var today = new DateOnly(2026, 8, 11); // Tuesday
        var range = DateRange.Create(today, today);
        range.TotalBusinessDays.Should().Be(1);
    }

    [Theory]
    [InlineData("2026-08-10", "2026-08-14", "2026-08-12", "2026-08-16", true)]  // overlap in middle
    [InlineData("2026-08-10", "2026-08-14", "2026-08-14", "2026-08-18", true)]  // share last/first day
    [InlineData("2026-08-10", "2026-08-14", "2026-08-15", "2026-08-20", false)] // adjacent, no overlap
    [InlineData("2026-08-10", "2026-08-14", "2026-08-01", "2026-08-09", false)] // before
    [InlineData("2026-08-10", "2026-08-20", "2026-08-12", "2026-08-15", true)]  // contained within
    [Trait("Category", "Unit")]
    public void OverlapsWith_ReturnsExpected(
        string s1, string e1, string s2, string e2, bool expected)
    {
        var a = DateRange.Create(DateOnly.Parse(s1), DateOnly.Parse(e1));
        var b = DateRange.Create(DateOnly.Parse(s2), DateOnly.Parse(e2));

        a.OverlapsWith(b).Should().Be(expected);
        b.OverlapsWith(a).Should().Be(expected); // symmetry
    }
}
