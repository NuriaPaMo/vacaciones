using FluentAssertions;
using Notifications.Domain.Notifications;
using System.Text;
using VacationManagement.Domain.VacationRequests.ValueObjects;
using Xunit;

namespace Notifications.Domain.Tests.Notifications;

// T012: Notification.CanRetry(), ActionLink expiry, NotificationTemplate.Render() all 11 variables
public class NotificationDomainTests
{
    private static readonly EmployeeId Recipient = EmployeeId.New();
    private static readonly EmployeeId SystemUser = EmployeeId.New();
    private static readonly byte[] HmacKey = Encoding.UTF8.GetBytes("test-secret-32-bytes-padding!!!!!");

    // ─── Notification.CanRetry (BR-088) ──────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void Notification_CreatedAsPending_CanRetryIsTrue()
    {
        var n = Notification.Create(NotificationEventType.RequestSubmitted,
            NotificationChannel.Email, Recipient, "test@company.com");

        n.CanRetry().Should().BeTrue();
        n.RetryCount.Should().Be(0);
    }

    [Theory]
    [InlineData(0, true)]   // 0 retries → can retry
    [InlineData(1, true)]   // 1 retry → can retry
    [InlineData(2, true)]   // 2 retries → can retry (max is 3)
    [InlineData(3, false)]  // 3 retries → exhausted
    [Trait("Category", "Unit")]
    public void Notification_CanRetry_ReturnsExpected(int failures, bool expected)
    {
        var n = Notification.Create(NotificationEventType.RequestSubmitted,
            NotificationChannel.Email, Recipient, "test@company.com");

        for (var i = 0; i < failures; i++)
            n.TryMarkFailed($"Error {i}");

        n.CanRetry().Should().Be(expected);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Notification_AfterThreeFailures_SetsMaxRetriesExceeded()
    {
        var n = Notification.Create(NotificationEventType.RequestSubmitted,
            NotificationChannel.Email, Recipient, "test@company.com");

        n.TryMarkFailed("E1").Should().BeTrue();  // can still retry
        n.TryMarkFailed("E2").Should().BeTrue();
        n.TryMarkFailed("E3").Should().BeFalse(); // exhausted
        n.Status.Should().Be(NotificationStatus.MaxRetriesExceeded);
        n.RetryCount.Should().Be(3);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Notification_TryMarkSent_SetsSentStatusAndTimestamp()
    {
        var n = Notification.Create(NotificationEventType.RequestSubmitted,
            NotificationChannel.Email, Recipient, "test@company.com");

        n.TryMarkSent().Should().BeTrue();
        n.Status.Should().Be(NotificationStatus.Sent);
        n.SentAt.Should().NotBeNull();
        n.ErrorMessage.Should().BeNull();
        n.CanRetry().Should().BeFalse();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Notification_TryMarkSent_Idempotent()
    {
        var n = Notification.Create(NotificationEventType.RequestSubmitted,
            NotificationChannel.Email, Recipient, "test@company.com");
        n.TryMarkSent();

        n.TryMarkSent().Should().BeFalse(); // already sent
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void Notification_EmailLowercasedOnCreate()
    {
        var n = Notification.Create(NotificationEventType.RequestSubmitted,
            NotificationChannel.Email, Recipient, "ANA.GARCIA@COMPANY.COM");
        n.RecipientEmail.Should().Be("ana.garcia@company.com");
    }

    // ─── ActionLink expiry (BR-089) ───────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void ActionLink_Generate_IsNotExpiredWithin7Days()
    {
        var link = ActionLink.Generate(VacationRequestId.New(), Recipient, HmacKey);

        link.IsExpired.Should().BeFalse();
        link.ExpiresAtUnix.Should().BeGreaterThan(DateTimeOffset.UtcNow.ToUnixTimeSeconds());
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void ActionLink_Validate_ReturnsTrueForFreshToken()
    {
        var reqId = VacationRequestId.New();
        var link = ActionLink.Generate(reqId, Recipient, HmacKey);

        var valid = ActionLink.Validate(link.Token, reqId, Recipient, link.ExpiresAtUnix, HmacKey);
        valid.Should().BeTrue();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void ActionLink_Validate_ReturnsFalseForExpiredToken()
    {
        var reqId = VacationRequestId.New();
        var link = ActionLink.Generate(reqId, Recipient, HmacKey);
        var pastExpiry = DateTimeOffset.UtcNow.AddDays(-8).ToUnixTimeSeconds();

        var valid = ActionLink.Validate(link.Token, reqId, Recipient, pastExpiry, HmacKey);
        valid.Should().BeFalse(); // EXPIRED
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void ActionLink_Validate_ReturnsFalseForWrongRecipient()
    {
        var reqId = VacationRequestId.New();
        var link = ActionLink.Generate(reqId, Recipient, HmacKey);
        var otherUser = EmployeeId.New();

        // BR-089: token is user-scoped
        var valid = ActionLink.Validate(link.Token, reqId, otherUser, link.ExpiresAtUnix, HmacKey);
        valid.Should().BeFalse();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void ActionLink_Validate_ReturnsFalseForTamperedToken()
    {
        var reqId = VacationRequestId.New();
        var link = ActionLink.Generate(reqId, Recipient, HmacKey);

        var valid = ActionLink.Validate("tampered_token", reqId, Recipient, link.ExpiresAtUnix, HmacKey);
        valid.Should().BeFalse();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void ActionLink_ToUrl_ContainsRequestIdAndToken()
    {
        var reqId = VacationRequestId.New();
        var link = ActionLink.Generate(reqId, Recipient, HmacKey);

        var url = link.ToUrl("https://app.company.com");
        url.Should().Contain(reqId.Value.ToString());
        url.Should().Contain("token=");
        url.Should().Contain("exp=");
    }

    // ─── NotificationTemplate.Render — all 11 variables ──────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void NotificationTemplate_Render_ReplacesAllKnownVariables()
    {
        var template = NotificationTemplate.Create(
            NotificationEventType.RequestSubmitted,
            NotificationChannel.Email,
            subject: "New request from {{employee_name}}",
            bodyTemplate: "{{employee_name}} requests {{start_date}} to {{end_date}} " +
                          "({{total_days}} days). Status: {{status}}. " +
                          "Approver: {{approver_name}}. Reason: {{rejection_reason}}. " +
                          "Link: {{action_url}}. " +
                          "Capacity: {{capacity_percent}}% for {{period_start}}–{{period_end}}.",
            createdBy: SystemUser);

        var data = new Dictionary<string, object>
        {
            ["employee_name"] = "Ana García",
            ["start_date"] = "2026-08-10",
            ["end_date"] = "2026-08-14",
            ["total_days"] = "5",
            ["status"] = "Pending",
            ["approver_name"] = "Carlos Ruiz",
            ["rejection_reason"] = "Coverage gap",
            ["action_url"] = "https://app/requests/123",
            ["capacity_percent"] = "75",
            ["period_start"] = "2026-08-10",
            ["period_end"] = "2026-08-14"
        };

        var body = template.Render(data);
        var subject = template.RenderSubject(data);

        body.Should().NotContain("{{"); // all tokens replaced
        body.Should().Contain("Ana García");
        body.Should().Contain("2026-08-10");
        body.Should().Contain("75%");
        subject.Should().Be("New request from Ana García");
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void NotificationTemplate_Render_UnknownVariables_LeftEmpty()
    {
        var template = NotificationTemplate.Create(
            NotificationEventType.RequestSubmitted, NotificationChannel.Email,
            "Subject", "Hello {{employee_name}}, unknown={{UNKNOWN_VAR}}",
            SystemUser);

        var body = template.Render(new Dictionary<string, object>
        {
            ["employee_name"] = "Ana"
        });

        body.Should().Contain("Ana");
        body.Should().Contain("unknown="); // unknown var replaced with empty string
        body.Should().NotContain("{{UNKNOWN_VAR}}");
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void NotificationTemplate_Update_ChangesFieldsAndTimestamp()
    {
        var template = NotificationTemplate.Create(
            NotificationEventType.RequestSubmitted, NotificationChannel.Email,
            "Old Subject", "Old body", SystemUser);

        template.Update("New Subject", "New body {{employee_name}}", SystemUser);

        template.Subject.Should().Be("New Subject");
        template.BodyTemplate.Should().Contain("New body");
    }

    [Fact]
    [Trait("Category", "Unit")]
    public void NotificationTemplate_Deactivate_SetsIsActiveFalse()
    {
        var template = NotificationTemplate.Create(
            NotificationEventType.RequestSubmitted, NotificationChannel.Email,
            "Sub", "Body", SystemUser);

        template.Deactivate();
        template.IsActive.Should().BeFalse();
    }

    // ─── CapacityAlert ────────────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public void CapacityAlert_Create_SetsAllFields()
    {
        var deptId = Guid.NewGuid();
        var start = new DateOnly(2026, 8, 10);
        var end = new DateOnly(2026, 8, 14);

        var alert = CapacityAlert.Create(deptId, start, end, CapacityAlertLevel.Critical, 78m);

        alert.DepartmentId.Should().Be(deptId);
        alert.Level.Should().Be(CapacityAlertLevel.Critical);
        alert.CapacityPercent.Should().Be(78m);
        alert.AlertedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(2));
    }
}
