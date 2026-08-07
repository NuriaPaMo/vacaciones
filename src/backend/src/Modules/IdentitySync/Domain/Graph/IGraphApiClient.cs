namespace IdentitySync.Domain.Graph;

// Port — implemented in Infrastructure using Microsoft.Graph SDK + DefaultAzureCredential
public interface IGraphApiClient
{
    // Cursor-based paging (100 users/page, @odata.nextLink) — BR-054
    IAsyncEnumerable<AdUserDto> GetAllUsersAsync(CancellationToken ct = default);

    // Fetch the AD groups of a user (for role assignment BR-058)
    Task<IReadOnlyList<string>> GetUserGroupNamesAsync(string userId, CancellationToken ct = default);
}
