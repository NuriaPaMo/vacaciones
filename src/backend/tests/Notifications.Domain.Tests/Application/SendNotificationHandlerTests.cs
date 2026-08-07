using FluentAssertions;
using Notifications.Domain.Application;
using Notifications.Domain.Notifications;
using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;
using Xunit;

namespace Notifications.Domain.Tests.Application;

// T013: SendNotificationHandler — template rendered → email sent; retry on failure; no template → graceful fail
public class SendNotificationHandlerTests
{
    private static readonly EmployeeId SystemUser = EmployeeId.New();
    private static readonly EmployeeId Recipient = EmployeeId.New();

    // ─── Fakes ───────────────────────────────────────────────────────────────

    private sealed class FakeTemplateRepo : INotificationTemplateRepository
    {
        private readonly NotificationTemplate? _template;
        public FakeTemplateRepo(NotificationTemplate? template) => _template = template;
        public Task<NotificationTemplate?> GetActiveAsync(
            NotificationEventType _, NotificationChannel __, CancellationToken ___) =>
            Task.FromResult(_template);
        public Task SaveAsync(NotificationTemplate _, CancellationToken __) => Task.CompletedTask;
    }

    private sealed class FakeNotificationRepo : INotificationRepository
    {
        public Notification? Saved { get; private set; }
        public Task SaveAsync(Notification n, CancellationToken _) { Saved = n; return Task.CompletedTask; }
    }

    private sealed class FakeEmailSender : IEmailSender
    {
        private readonly Queue<Exception?> _responses;
        public List<(string To, string Subject, string Body)> Sent { get; } = [];

        public FakeEmailSender(params Exception?[] responses) =>
            _responses = new Queue<Exception?>(responses);

        public Task SendAsync(string to, string subject, string body, CancellationToken _)
        {
            var ex = _responses.Count > 0 ? _responses.Dequeue() : null;
            if (ex is not null) throw ex;
            Sent.Add((to, subject, body));
            return Task.CompletedTask;
        }
    }

    private static NotificationTemplate MakeTemplate() =>
        NotificationTemplate.Create(
            NotificationEventType.RequestSubmitted, NotificationChannel.Email,
            subject: "New request from {{employee_name}}",
            bodyTemplate: "<p>{{employee_name}} requests {{start_date}} to {{end_date}}</p>",
            createdBy: SystemUser);

    private static SendNotificationCommand MakeCommand() =>
        new(
            EventType: NotificationEventType.RequestSubmitted,
            Channel: NotificationChannel.Email,
            RecipientId: Recipient,
            RecipientEmail: "carlos.ruiz@company.com",
            RequestId: VacationRequestId.New(),
            TemplateData: new Dictionary<string, object>
            {
                ["employee_name"] = "Ana García",
                ["start_date"] = "2026-08-10",
                ["end_date"] = "2026-08-14"
            });

    // ─── Tests ───────────────────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Handle_ValidTemplate_SendsEmailAndMarksSent()
    {
        var repo = new FakeNotificationRepo();
        var emailSender = new FakeEmailSender(); // always succeeds
        var handler = new SendNotificationHandler(
            new FakeTemplateRepo(MakeTemplate()), repo, emailSender);

        await handler.HandleAsync(MakeCommand());

        emailSender.Sent.Should().ContainSingle(m => m.To == "carlos.ruiz@company.com");
        emailSender.Sent[0].Body.Should().Contain("Ana García");
        emailSender.Sent[0].Subject.Should().Be("New request from Ana García");
        repo.Saved!.Status.Should().Be(NotificationStatus.Sent);
        repo.Saved.SentAt.Should().NotBeNull();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Handle_SmtpFailureOnce_NotificationSetToFailed()
    {
        var repo = new FakeNotificationRepo();
        var emailSender = new FakeEmailSender(new Exception("SMTP timeout")); // first call throws
        var handler = new SendNotificationHandler(
            new FakeTemplateRepo(MakeTemplate()), repo, emailSender);

        await handler.HandleAsync(MakeCommand());

        repo.Saved!.Status.Should().Be(NotificationStatus.Failed);
        repo.Saved.RetryCount.Should().Be(1);
        repo.Saved.ErrorMessage.Should().Contain("SMTP timeout");
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Handle_NoTemplateSeeded_GracefullyFailsWithoutThrowing()
    {
        var repo = new FakeNotificationRepo();
        var handler = new SendNotificationHandler(
            new FakeTemplateRepo(null), repo, new FakeEmailSender());

        var act = async () => await handler.HandleAsync(MakeCommand());
        await act.Should().NotThrowAsync();

        repo.Saved!.Status.Should().Be(NotificationStatus.Failed);
        repo.Saved.ErrorMessage.Should().Contain("No active template");
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Handle_EmailSentSuccessfully_PersistsAuditRecord()
    {
        var repo = new FakeNotificationRepo();
        var handler = new SendNotificationHandler(
            new FakeTemplateRepo(MakeTemplate()), repo, new FakeEmailSender());

        await handler.HandleAsync(MakeCommand());

        repo.Saved.Should().NotBeNull();
        repo.Saved!.EventType.Should().Be(NotificationEventType.RequestSubmitted);
        repo.Saved.Channel.Should().Be(NotificationChannel.Email);
        repo.Saved.RecipientId.Should().Be(Recipient);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task Handle_TeamsChannel_DoesNotCallEmailSender()
    {
        var emailSender = new FakeEmailSender();
        var repo = new FakeNotificationRepo();
        var teamsTemplate = NotificationTemplate.Create(
            NotificationEventType.CapacityCritical, NotificationChannel.Teams,
            "Alert", "Capacity alert {{capacity_percent}}%", SystemUser);

        var handler = new SendNotificationHandler(
            new FakeTemplateRepo(teamsTemplate), repo, emailSender);

        await handler.HandleAsync(new SendNotificationCommand(
            NotificationEventType.CapacityCritical, NotificationChannel.Teams,
            Recipient, "carlos@co.com", null,
            new Dictionary<string, object> { ["capacity_percent"] = "80" }));

        emailSender.Sent.Should().BeEmpty(); // Teams channel → no email
        repo.Saved!.Status.Should().Be(NotificationStatus.Sent);
    }
}
