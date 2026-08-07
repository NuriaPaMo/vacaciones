namespace IdentitySync.Domain.Graph;

// DTO mirroring the Microsoft Graph API User resource fields we consume (BR-054–058)
public sealed record AdUserDto(
    string Id,               // AD Object ID — becomes ExternalAdId
    string? GivenName,
    string? Surname,
    string? DisplayName,
    string? Mail,
    string? Department,
    string? JobTitle,
    bool AccountEnabled,
    string? ManagerId         // resolved from /manager endpoint or $expand
);
