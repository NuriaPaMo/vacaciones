using System.Security.Cryptography;
using System.Text;
using VacationManagement.Domain.Common;
using VacationManagement.Domain.VacationRequests.ValueObjects;

namespace Notifications.Domain.Notifications;

// BR-089: HMAC-SHA256 signed; user-scoped; 7-day expiry
// BR-091: links navigate to the page; do NOT auto-approve/reject
// Secret loaded from Key Vault — never stored in code (T018-QG)
public sealed class ActionLink
{
    private const int ExpiryDays = 7;

    public VacationRequestId RequestId { get; }
    public EmployeeId RecipientId { get; }
    public long ExpiresAtUnix { get; }
    public string Token { get; }

    private ActionLink(VacationRequestId requestId, EmployeeId recipientId,
        long expiresAt, string token)
    {
        RequestId = requestId;
        RecipientId = recipientId;
        ExpiresAtUnix = expiresAt;
        Token = token;
    }

    public bool IsExpired => DateTimeOffset.UtcNow.ToUnixTimeSeconds() > ExpiresAtUnix;

    // Generates a signed action link
    public static ActionLink Generate(
        VacationRequestId requestId,
        EmployeeId recipientId,
        byte[] hmacKey)
    {
        var exp = DateTimeOffset.UtcNow.AddDays(ExpiryDays).ToUnixTimeSeconds();
        var token = ComputeHmac(hmacKey, requestId.Value, recipientId.Value, exp);
        return new ActionLink(requestId, recipientId, exp, token);
    }

    // BR-089: token is user-scoped — validates recipientId matches original
    public static bool Validate(
        string token,
        VacationRequestId requestId,
        EmployeeId recipientId,
        long expiresAtUnix,
        byte[] hmacKey)
    {
        if (DateTimeOffset.UtcNow.ToUnixTimeSeconds() > expiresAtUnix)
            return false; // EXPIRED

        var expected = ComputeHmac(hmacKey, requestId.Value, recipientId.Value, expiresAtUnix);
        return CryptographicOperations.FixedTimeEquals(
            Encoding.UTF8.GetBytes(expected),
            Encoding.UTF8.GetBytes(token));
    }

    public string ToUrl(string baseUrl) =>
        $"{baseUrl.TrimEnd('/')}/app/requests/{RequestId.Value}?token={Uri.EscapeDataString(Token)}&exp={ExpiresAtUnix}&uid={RecipientId.Value}";

    private static string ComputeHmac(byte[] key, Guid requestId, Guid recipientId, long exp)
    {
        var message = Encoding.UTF8.GetBytes($"{requestId}:{recipientId}:{exp}");
        using var hmac = new HMACSHA256(key);
        var hash = hmac.ComputeHash(message);
        return Convert.ToBase64String(hash);
    }
}
