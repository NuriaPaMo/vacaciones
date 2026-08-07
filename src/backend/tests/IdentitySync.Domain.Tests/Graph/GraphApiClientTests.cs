using System.Net;
using System.Text;
using System.Text.Json;
using FluentAssertions;
using IdentitySync.Domain.Graph;
using Xunit;

namespace IdentitySync.Domain.Tests.Graph;

// T010: GraphApiClient paged responses + 503 handling — uses custom HttpMessageHandler (no WireMock)
// WireMock.Net removed due to high-severity CVEs in transitive Scriban.Signed dependency
public class GraphApiClientTests
{
    // ─── Helpers ─────────────────────────────────────────────────────────────

    // Builds a Graph API /users response page with @odata.nextLink when nextUrl is provided
    private static string BuildUsersPage(IEnumerable<object> users, string? nextUrl)
    {
        var obj = new Dictionary<string, object>
        {
            ["value"] = users.ToArray()
        };
        if (nextUrl is not null)
            obj["@odata.nextLink"] = nextUrl;
        return JsonSerializer.Serialize(obj);
    }

    private static object BuildAdUser(string id, string name, bool enabled = true) =>
        new
        {
            id,
            givenName = name,
            surname = "Test",
            displayName = $"{name} Test",
            mail = $"{name.ToLower()}@company.com",
            department = "Engineering",
            accountEnabled = enabled
        };

    // Custom handler that responds with a queue of predefined responses
    private sealed class QueuedHandler(Queue<(HttpStatusCode, string)> queue)
        : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request, CancellationToken cancellationToken)
        {
            if (!queue.TryDequeue(out var next))
                throw new InvalidOperationException("No more responses queued.");

            var (code, body) = next;
            return Task.FromResult(new HttpResponseMessage(code)
            {
                Content = new StringContent(body, Encoding.UTF8, "application/json")
            });
        }
    }

    // ─── Tests ───────────────────────────────────────────────────────────────

    [Fact]
    [Trait("Category", "Unit")]
    public async Task GetAllUsersAsync_SinglePage_ReturnsAllUsers()
    {
        var page = BuildUsersPage(
            [BuildAdUser("u1", "Alice"), BuildAdUser("u2", "Bob")],
            nextUrl: null);

        var queue = new Queue<(HttpStatusCode, string)>([(HttpStatusCode.OK, page)]);
        var client = new TestGraphApiClient(new QueuedHandler(queue));

        var users = new List<AdUserDto>();
        await foreach (var u in client.GetAllUsersAsync())
            users.Add(u);

        users.Should().HaveCount(2);
        users[0].Id.Should().Be("u1");
        users[1].Id.Should().Be("u2");
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task GetAllUsersAsync_MultiplePages_YieldsAllUsersAcrossPages()
    {
        // Simulate 3 pages: page1 → nextLink → page2 → nextLink → page3
        var page1 = BuildUsersPage(
            Enumerable.Range(1, 3).Select(i => BuildAdUser($"u{i}", $"User{i}")),
            nextUrl: "https://graph/page2");
        var page2 = BuildUsersPage(
            Enumerable.Range(4, 3).Select(i => BuildAdUser($"u{i}", $"User{i}")),
            nextUrl: "https://graph/page3");
        var page3 = BuildUsersPage(
            Enumerable.Range(7, 2).Select(i => BuildAdUser($"u{i}", $"User{i}")),
            nextUrl: null);

        var queue = new Queue<(HttpStatusCode, string)>([
            (HttpStatusCode.OK, page1),
            (HttpStatusCode.OK, page2),
            (HttpStatusCode.OK, page3)]);

        var client = new TestGraphApiClient(new QueuedHandler(queue));

        var users = new List<AdUserDto>();
        await foreach (var u in client.GetAllUsersAsync())
            users.Add(u);

        users.Should().HaveCount(8);
        users.Select(u => u.Id).Should().BeEquivalentTo(
            Enumerable.Range(1, 8).Select(i => $"u{i}"));
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task GetAllUsersAsync_EmptyPage_ReturnsNoUsers()
    {
        var page = BuildUsersPage([], nextUrl: null);
        var queue = new Queue<(HttpStatusCode, string)>([(HttpStatusCode.OK, page)]);
        var client = new TestGraphApiClient(new QueuedHandler(queue));

        var users = new List<AdUserDto>();
        await foreach (var u in client.GetAllUsersAsync())
            users.Add(u);

        users.Should().BeEmpty();
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task GetAllUsersAsync_Disabled_User_IsIncluded_AccountEnabledFalse()
    {
        var page = BuildUsersPage([BuildAdUser("u-disabled", "Former", enabled: false)], nextUrl: null);
        var queue = new Queue<(HttpStatusCode, string)>([(HttpStatusCode.OK, page)]);
        var client = new TestGraphApiClient(new QueuedHandler(queue));

        var users = new List<AdUserDto>();
        await foreach (var u in client.GetAllUsersAsync())
            users.Add(u);

        // Graph client returns all users including disabled; the handler applies BR-056
        users.Should().ContainSingle(u => u.Id == "u-disabled" && !u.AccountEnabled);
    }

    [Fact]
    [Trait("Category", "Unit")]
    public async Task GetUserGroupNamesAsync_ReturnsGroupDisplayNames()
    {
        var groupsPage = JsonSerializer.Serialize(new
        {
            value = new[]
            {
                new { displayName = "VacationSystem-ProjectManagers", id = "g1" },
                new { displayName = "AllEmployees", id = "g2" }
            }
        });

        var queue = new Queue<(HttpStatusCode, string)>([(HttpStatusCode.OK, groupsPage)]);
        var client = new TestGraphApiClient(new QueuedHandler(queue));

        var groups = await client.GetUserGroupNamesAsync("u1");

        groups.Should().Contain("VacationSystem-ProjectManagers");
        groups.Should().Contain("AllEmployees");
    }
}

// Testable implementation of IGraphApiClient that accepts a custom HttpMessageHandler
internal sealed class TestGraphApiClient : IGraphApiClient
{
    private readonly HttpClient _http;

    public TestGraphApiClient(HttpMessageHandler handler)
    {
        _http = new HttpClient(handler)
        {
            BaseAddress = new Uri("https://graph.microsoft.com/v1.0/")
        };
    }

    public async IAsyncEnumerable<AdUserDto> GetAllUsersAsync(
        [System.Runtime.CompilerServices.EnumeratorCancellation] CancellationToken ct = default)
    {
        string? nextUrl = "users?$select=id,givenName,surname,mail,department,accountEnabled&$top=100";

        while (nextUrl is not null)
        {
            var response = await _http.GetAsync(nextUrl, ct);
            response.EnsureSuccessStatusCode();

            var json = await response.Content.ReadAsStringAsync(ct);
            var doc = JsonDocument.Parse(json);

            foreach (var userEl in doc.RootElement.GetProperty("value").EnumerateArray())
            {
                yield return new AdUserDto(
                    Id: userEl.GetProperty("id").GetString()!,
                    GivenName: GetStringOrNull(userEl, "givenName"),
                    Surname: GetStringOrNull(userEl, "surname"),
                    DisplayName: GetStringOrNull(userEl, "displayName"),
                    Mail: GetStringOrNull(userEl, "mail"),
                    Department: GetStringOrNull(userEl, "department"),
                    JobTitle: GetStringOrNull(userEl, "jobTitle"),
                    AccountEnabled: userEl.TryGetProperty("accountEnabled", out var ae) && ae.GetBoolean(),
                    ManagerId: null);
            }

            nextUrl = doc.RootElement.TryGetProperty("@odata.nextLink", out var next)
                ? next.GetString()
                : null;
        }
    }

    public async Task<IReadOnlyList<string>> GetUserGroupNamesAsync(
        string userId, CancellationToken ct = default)
    {
        var response = await _http.GetAsync(
            $"users/{userId}/memberOf?$select=displayName", ct);
        response.EnsureSuccessStatusCode();

        var json = await response.Content.ReadAsStringAsync(ct);
        var doc = JsonDocument.Parse(json);

        return doc.RootElement.GetProperty("value")
            .EnumerateArray()
            .Select(g => g.TryGetProperty("displayName", out var dn)
                ? dn.GetString() ?? string.Empty
                : string.Empty)
            .Where(n => n.Length > 0)
            .ToList();
    }

    private static string? GetStringOrNull(JsonElement el, string prop) =>
        el.TryGetProperty(prop, out var v) && v.ValueKind == JsonValueKind.String
            ? v.GetString()
            : null;
}
